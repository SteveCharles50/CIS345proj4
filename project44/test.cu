#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <cuda_runtime.h>

#define N 10000000
#define THREADS_PER_BLOCK 1024

__global__ void vector_add(float *out, float *a, float *b, int n) {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride) {
        out[i] = a[i] + b[i];
    }
}

int main() {
    clock_t start, end;
    double cpuTimeUsed;

    float *h_a, *h_b, *h_out;  // Host pointers
    float *d_a, *d_b, *d_out;  // Device pointers

    size_t size = sizeof(float) * N;

    // Allocate host memory
    h_a = (float *)malloc(size);
    h_b = (float *)malloc(size);
    h_out = (float *)malloc(size);

    // Initialize host arrays
    for (int i = 0; i < N; i++) {
        h_a[i] = 1.0f;
        h_b[i] = 2.0f;
    }

    // Allocate device memory
    cudaMalloc((void **)&d_a, size);
    cudaMalloc((void **)&d_b, size);
    cudaMalloc((void **)&d_out, size);

    // Copy data from host to device
    cudaMemcpy(d_a, h_a, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, size, cudaMemcpyHostToDevice);

    // Start timing
    start = clock();

    // Launch kernel
    int blocks = (N + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;
    vector_add<<<blocks, THREADS_PER_BLOCK>>>(d_out, d_a, d_b, N);

    // Copy result back to host
    cudaMemcpy(h_out, d_out, size, cudaMemcpyDeviceToHost);

    // Stop timing
    end = clock();

    cpuTimeUsed = ((double)(end - start)) / CLOCKS_PER_SEC;
    printf("Time taken: %f seconds\n", cpuTimeUsed);

    // Free device memory
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_out);

    // Free host memory
    free(h_a);
    free(h_b);
    free(h_out);

    return 0;
}
