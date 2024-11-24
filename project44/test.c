#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#define N 1000
#define THREADS_PER_BLOCK 256

// Function to perform vector addition
void vector_add(float *out, float *a, float *b, int n) {
    for (int i = 0; i < n; i++) {
        out[i] = a[i] + b[i];
    }
}

int main() {
    clock_t start, end;
    double cpuTimeUsed;

    float *h_a, *h_b, *h_out;  // Host pointers

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

    // Start timing
    start = clock();

    // Perform vector addition on the CPU
    vector_add(h_out, h_a, h_b, N);

    // Stop timing
    end = clock();

    cpuTimeUsed = ((double)(end - start)) / CLOCKS_PER_SEC;
    printf("Time taken: %f seconds\n", cpuTimeUsed);

    // Free host memory
    free(h_a);
    free(h_b);
    free(h_out);

    return 0;
}
