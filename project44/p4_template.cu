#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#define EPSILON (0.001f)
#define notEqual(x,y)     (fabs((x) - (y)) > EPSILON)

typedef unsigned long long SysClock;

static SysClock currentTicks() {
    timespec spec;
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &spec);
    return (SysClock)((float)(spec.tv_sec) * 1e9 + (float)(spec.tv_nsec));
}

static double secondsPerTick() {
    static int initialized = 0;
    static double secondsPerTick_val;
    if (initialized) return secondsPerTick_val;
    FILE *fp = fopen("/proc/cpuinfo","r");
    char input[1024];
    if (!fp) {
        fprintf(stderr, "resetScale failed: couldn't find /proc/cpuinfo.");
	exit(-1);
    }
    secondsPerTick_val = 1e-9;
    while (!feof(fp) && fgets(input, 1024, fp)) {
        float GHz, MHz;
	if (strstr(input, "model name")) {
	    char* at_sign = strstr(input, "@");
	    if (at_sign) {
	        char* after_at = at_sign + 1;
		char* GHz_str = strstr(after_at, "GHz");
		char* MHz_str = strstr(after_at, "MHz");
		if (GHz_str) {
		    *GHz_str = '\0';
		    if (1 == sscanf(after_at, "%f", &GHz)) {
		        //printf("GHz = %f\n", GHz);
			secondsPerTick_val = 1e-9f / GHz;
			break;
		    }
		} else if (MHz_str) {
		    *MHz_str = '\0';
		    if (1 == sscanf(after_at, "%f", &MHz)) {
		        //printf("MHz = %f\n", MHz);
			secondsPerTick_val = 1e-6f / GHz;
			break;
		    }
		}
	    }
	} else if (1 == sscanf(input, "cpu MHz : %f", &MHz)) {
	    //printf("MHz = %f\n", MHz);
	    secondsPerTick_val = 1e-6f / MHz;
	    break;
	}
    }
    fclose(fp);
    initialized = 1;
    return secondsPerTick_val;
}

static double currentSeconds() {
    return currentTicks() * secondsPerTick();
}

float toBW(int bytes, float sec) {
  return (float)(bytes) / (1024. * 1024. * 1024.) / sec;
}

__global__ void faxpy_1blk_kernel(int N, float alpha, float *x, float *y, float *result) {
    // TODO insert your CUDA kernel code here
    // TODO one block of threads
    for(int i = 0; i < N; i++){
		result[i] = alpha * x[i] + y[i];
    }
}


__global__ void faxpy_mblk_kernel(int N, float alpha, float* x, float* y, float* result) {

    // TODO insert your CUDA kernel code here
    // TODO multi-blocks of threads
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if(tid < N){
      result[tid] = alpha * x[tid] + y[tid];
    }




}

void faxpyCudaMULT(int N, float alpha, float* xarray, float* yarray, float* resultarray) {

    int totalBytes = sizeof(float) * 3 * N;

    // compute number of blocks and threads per block
    const int threadsPerBlock = 512;
    const int blocks = (N + threadsPerBlock - 1) / threadsPerBlock;

	float *d_x, *d_y, *d_result;

    //
    // TODO allocate device memory buffers on the GPU using cudaMalloc
    //
	cudaMalloc((void**)&d_x, sizeof(float) * N);
	cudaMalloc((void**)&d_y, sizeof(float) * N);
	cudaMalloc((void**)&d_result, sizeof(float) * N);

    // start timing after allocation of device memory
    double startTimeMult = currentSeconds();

    //
    // TODO copy input arrays to the GPU using cudaMemcpy
    //

	cudaMemcpy(d_x, xarray, sizeof(float) * N, cudaMemcpyHostToDevice);
	cudaMemcpy(d_y, yarray, sizeof(float) * N, cudaMemcpyHostToDevice);

    double midTime1Mult = currentSeconds();

    //
    // TODO run kernel, either 1-block kernel or multi-block kernel
    //
	faxpy_mblk_kernel<<<blocks,threadsPerBlock>>>(N, alpha, d_x, d_y, d_result);
    // IMPORTANT, wait for the completion at GPU
    cudaDeviceSynchronize();

    double midTime2Mult = currentSeconds();

    //
    // TODO copy result from GPU using cudaMemcpy
    //
	cudaMemcpy(resultarray, d_result, sizeof(float) * N, cudaMemcpyDeviceToHost);

    // end timing after result has been copied back into host memory
    double endTime = currentSeconds();

    cudaError_t errCode = cudaPeekAtLastError();
    if (errCode != cudaSuccess) {
        fprintf(stderr, "WARNING: A CUDA error occured: code=%d, %s\n", errCode, cudaGetErrorString(errCode));
    }

    double overallDuration = endTime - startTimeMult;
    printf("Overall using multiple blocks: %.3f ms\t\t[%.3f GB/s]\n", 1000.f * overallDuration, toBW(totalBytes, overallDuration));

    double transferDur = midTime1Mult - startTimeMult;
    printf("xy array --> device %.3f ms\n", 1000.f * transferDur);

    double gpu_compute_dur = midTime2Mult - midTime1Mult;
    printf("GPU computation duration using multiple blocks %.3f ms\n", 1000.f * gpu_compute_dur);

    // TODO free memory buffers on the GPU
    cudaFree(d_x);
	cudaFree(d_y);
	cudaFree(d_result);

}


void faxpyCudaSingle(int N, float alpha, float* xarray, float* yarray, float* resultarray) {

    int totalBytes = sizeof(float) * 3 * N;

    // compute number of blocks and threads per block
    const int threadsPerBlock = 512;

	float *d_x, *d_y, *d_result;

    //
    // TODO allocate device memory buffers on the GPU using cudaMalloc
    //
	cudaMalloc((void**)&d_x, sizeof(float) * N);
	cudaMalloc((void**)&d_y, sizeof(float) * N);
	cudaMalloc((void**)&d_result, sizeof(float) * N);

    // start timing after allocation of device memory
    double startTimeMult = currentSeconds();

    //
    // TODO copy input arrays to the GPU using cudaMemcpy
    //

	cudaMemcpy(d_x, xarray, sizeof(float) * N, cudaMemcpyHostToDevice);
	cudaMemcpy(d_y, yarray, sizeof(float) * N, cudaMemcpyHostToDevice);

    double midTime1Mult = currentSeconds();

    //
    // TODO run kernel, either 1-block kernel or multi-block kernel
    //
	faxpy_1blk_kernel<<<1,threadsPerBlock>>>(N, alpha, d_x, d_y, d_result);
    // IMPORTANT, wait for the completion at GPU
    cudaDeviceSynchronize();

    double midTime2Mult = currentSeconds();

    //
    // TODO copy result from GPU using cudaMemcpy
    //
	cudaMemcpy(resultarray, d_result, sizeof(float) * N, cudaMemcpyDeviceToHost);

    // end timing after result has been copied back into host memory
    double endTime = currentSeconds();

    cudaError_t errCode = cudaPeekAtLastError();
    if (errCode != cudaSuccess) {
        fprintf(stderr, "WARNING: A CUDA error occured: code=%d, %s\n", errCode, cudaGetErrorString(errCode));
    }

    double overallDuration = endTime - startTimeMult;
    printf("Overall using single block: %.3f ms\t\t[%.3f GB/s]\n", 1000.f * overallDuration, toBW(totalBytes, overallDuration));

    double transferDur = midTime1Mult - startTimeMult;
    printf("xy array --> device %.3f ms\n", 1000.f * transferDur);

    double gpu_compute_dur = midTime2Mult - midTime1Mult;
    printf("GPU computation duration using single block %.3f ms\n", 1000.f * gpu_compute_dur);

    // TODO free memory buffers on the GPU
    cudaFree(d_x);
	cudaFree(d_y);
	cudaFree(d_result);

}

void faxpyCPU(int N, float alpha, float *xarray, float *yarray, float *resultarray) {
    double startTime = currentSeconds();
    for (int i = 0; i < N; i++) {
        resultarray[i] = alpha * xarray[i] + yarray[i];
    }
    double endTime = currentSeconds();
    double cpu_dur = endTime - startTime;
    printf("CPU computation duration %.3f ms\n", 1000.f * cpu_dur);
}

int main(int argc, char** argv)
{

    int N = 20 * 1000 * 1000;

    const float alpha = 5.0f;
    const float max = 999.0f;
    float* xarray = (float *)malloc(sizeof(float)*N);
    float* yarray = (float *)malloc(sizeof(float)*N);
    float* resultarray = (float *)malloc(sizeof(float)*N);
	float* resultarraySingle = (float *)malloc(sizeof(float)*N);
    float* checkarray = (float *)malloc(sizeof(float)*N);

    for (int i=0; i<N; i++) {
	xarray[i] = ((float)rand()/(float)(RAND_MAX)) * max;
	yarray[i] = ((float)rand()/(float)(RAND_MAX)) * max;
        resultarray[i] = 0.f;
    }

    faxpyCudaMULT(N, alpha, xarray, yarray, resultarray);
	printf("\n");
	printf("\n");
	faxpyCudaSingle(N, alpha, xarray, yarray, resultarraySingle);
	printf("\n");
	printf("\n");
    faxpyCPU(N, alpha, xarray, yarray, checkarray);

    // Verify the FAXPY computatin at GPU is correct
    for (int i = 0; i < N; i++) {
      if (notEqual(checkarray[i], resultarray[i])) {
        fprintf(stderr, "Error: device axpy outputs incorrect result."
			" A[%d] = %.5f, expecting %.5f.\n", i, resultarray[i], checkarray[i]);
	exit(1);
      }
    }
    printf("device faxpy outputs are correct!\n");

	for (int i = 0; i < N; i++) {
		if (notEqual(checkarray[i], resultarraySingle[i])) {
			fprintf(stderr, "Error: device axpy outputs incorrect result."
				" A[%d] = %.5f, expecting %.5f.\n", i, resultarraySingle[i], checkarray[i]);
			exit(1);
		}
	}
	printf("single block faxpy outputs are correct!\n");

    free(xarray);
    free(yarray);
    free(resultarray);
    free(checkarray);

    return 0;
}

