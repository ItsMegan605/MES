#include "shared.h"
#include "shared.cu"


void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    totalThreads = file_size - target_string_len + 1;

    blocksPerGrid = totalThreads / threadsPerBlock + ((totalThreads % threadsPerBlock > 0) ? 1: 0);

    shared_memory_size = threadsPerBlock + target_string_len - 1; 

    cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(unsigned long long));

}



__global__ void parallelStringSearch(char* file_buffer, unsigned long long* occurrences){

    unsigned long long global_id = threadIdx.x + (unsigned long long)blockDim.x * blockIdx.x;
    int block_pos = threadIdx.x;
    int block_size = blockDim.x;

    unsigned int target_len = d_target_string_len;
    unsigned long long totalThreads = d_totalThreads;
    
    __shared__ unsigned long long local_occurrences;

    if(block_pos == 0)
        local_occurrences = 0;
    
    extern __shared__ char shared_buffer[];

    if(global_id < totalThreads + target_len - 1)
        shared_buffer[block_pos] = file_buffer[global_id];

    // gestire caso stringa_len - 1 > blocco ma stica
    if((block_pos < target_len- 1)  && (global_id + block_size < d_file_size))
        shared_buffer[block_size + block_pos] = file_buffer[block_size + global_id];

    __syncthreads();

    if(global_id < totalThreads){
        int i = 0;
        for(; i < target_len; i++){
            if(d_target_string[i] != shared_buffer[block_pos + i])
            break;
        }
        
        if(i == target_len)
            atomicAdd(&local_occurrences,1);
    }
    __syncthreads();

    if(block_pos == 0 && local_occurrences > 0)
        atomicAdd(occurrences,local_occurrences);

}

int main(int argc, char* argv[]);