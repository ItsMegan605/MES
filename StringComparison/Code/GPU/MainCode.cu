#include "shared.h"

#ifdef BENCHMARK

    #include "bench.cu"

#else

    #include "shared.cu"

#endif



void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    u64 totalThreads = file_size - target_string_len + 1;

    blocksPerGrid = totalThreads / threadsPerBlock + ((totalThreads % threadsPerBlock > 0) ? 1: 0);

    shared_memory_size = threadsPerBlock + target_string_len - 1; 

    cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(u64));

}



__global__ void parallelStringSearch(char* file_buffer, u64* occurrences){

    u64 global_id = threadIdx.x + (u64)blockDim.x * blockIdx.x;
    int block_pos = threadIdx.x;
    int block_size = blockDim.x;

    // provare a mettere variabili read only nei registri?
    
    extern __shared__ char shared_buffer[];

    if(global_id < d_totalThreads + d_target_string_len - 1)
        shared_buffer[block_pos] = file_buffer[global_id];

    // gestire caso stringa_len - 1 > blocco ma stica
    if((block_pos < d_target_string_len - 1)  && (global_id + block_size < d_file_size))
        shared_buffer[block_size + block_pos] = file_buffer[block_size + global_id];

    __syncthreads();

    if(global_id >= d_totalThreads)
        return;

    int i = 0;
    for(; i < d_target_string_len; i++){
        if(d_target_string[i] != shared_buffer[block_pos + i])
        break;
    }
    
    if(i == d_target_string_len)
        atomicAdd(occurrences,1);

}

int main(int argc, char* argv[]);