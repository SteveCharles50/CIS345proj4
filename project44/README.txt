Steve Charles ID: 2850400
Contribution: 100%

Design Details:
  {-[Overall design details]:
      -Kept two spererate implementations for calling both one block and multiblock computation
          -Both are called in main method and respective computations are done accurately
      -CPU calculation and comparison of array output of CPU and both GPU computations is done properly as well.
   }

  -contains a 1 block and multi block method for array addition computed based off of the total number of elements N/number of threads in each block
  -cudaMalloc =  memory allocation on Device(GPU)
  -cudaMemcpy = Memory copy from host to device or device to host based on specification
  -currentSeconds(): the current time during variable assignement
  -startTime: activated before copying the memory from host to device
  -midTime1: used to tell the time taken to during transfer
  -midTime2: used to tell the time the duration of the GPU computation
  -endtime: used to compute the full duration of the GPU computation
  -cudafree: Free cuda memory
  ^Adapted each of these variables to both single and multi-block exection

  Here is the expected input(breaking down the makefile):
                nvcc -o run p4_template.cu
                ./run
  Expected output:
                Overall using multiple blocks: 15.357 ms		[14.555 GB/s]
                xy array --> device 9.698 ms
                GPU computation duration using multiple blocks 0.939 ms


                Overall using single block: 1055.030 ms		[0.212 GB/s]
                xy array --> device 8.599 ms
                GPU computation duration using single block 1034.743 ms


                CPU computation duration 21.299 ms
                device faxpy outputs are correct!
                single block faxpy outputs are correct!

-The differences in computation time are significant:
    -multi-block execution yielded both the fastest computation and overall time
    -Single block execution had both the longest computation and overall time
    -CPU execution fits right in between both  
