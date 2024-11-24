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
}

__global__ void faxpy_mblk_kernel(int N, float alpha, float* x, float* y, float* result) {

    // TODO insert your CUDA kernel code here
    // TODO multi-blocks of threads
}

void faxpyCuda(int N, float alpha, float* xarray, float* yarray, float* resultarray) {

    int totalBytes = sizeof(float) * 3 * N;

    // compute number of blocks and threads per block
    const int threadsPerBlock = 512;
    const int blocks = (N + threadsPerBlock - 1) / threadsPerBlock;

    float* device_x;
    float* device_y;
    float* device_result;

    //
    // TODO allocate device memory buffers on the GPU using cudaMalloc
    //


    // start timing after allocation of device memory
    double startTime = currentSeconds();

    //
    // TODO copy input arrays to the GPU using cudaMemcpy
    //

    double midTime1 = currentSeconds();

    //
    // TODO run kernel, either 1-block kernel or multi-block kernel
    //

    // IMPORTANT, wait for the completion at GPU
    cudaDeviceSynchronize();

    double midTime2 = currentSeconds();

    //
    // TODO copy result from GPU using cudaMemcpy
    //

    // end timing after result has been copied back into host memory
    double endTime = currentSeconds();

    cudaError_t errCode = cudaPeekAtLastError();
    if (errCode != cudaSuccess) {
        fprintf(stderr, "WARNING: A CUDA error occured: code=%d, %s\n", errCode, cudaGetErrorString(errCode));
    }

    double overallDuration = endTime - startTime;
    printf("Overall: %.3f ms\t\t[%.3f GB/s]\n", 1000.f * overallDuration, toBW(totalBytes, overallDuration));

    double transferDur = midTime1 - startTime;
    printf("xy array --> device %.3f ms\n", 1000.f * transferDur);

    double gpu_compute_dur = midTime2 - midTime1;
    printf("GPU computation duration %.3f ms\n", 1000.f * gpu_compute_dur);

    // TODO free memory buffers on the GPU

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
    float* checkarray = (float *)malloc(sizeof(float)*N);

    for (int i=0; i<N; i++) {
	xarray[i] = ((float)rand()/(float)(RAND_MAX)) * max;
	yarray[i] = ((float)rand()/(float)(RAND_MAX)) * max;
        resultarray[i] = 0.f;
    }

    faxpyCuda(N, alpha, xarray, yarray, resultarray);

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

    free(xarray);
    free(yarray);
    free(resultarray);
    free(checkarray);

    return 0;
}

