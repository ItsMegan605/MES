#include "shared.h"

#ifdef BENCHMARK

    #include "bench.cu"

#else

    #include "shared.cu"

#endif

//NB: vars with d are the "copy" of the CPU parameters
__global__ void parallelStringSearch(char* file_buffer, u64* occurrences);

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);

    shared_memory_size = threadsPerBlock + target_string_len - 1;

    
    // We ask CUDA: "Given my threadsPerBlock, how many blocks can I 
    // put at most in a single Streaming Multiprocessor (SM)?"

    #ifdef MAX_OCCUPANCY
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            parallelStringSearch, 
            threadsPerBlock, 
            shared_memory_size
        );  
    #endif

    // We calculate the total grid by multiplying the blocks per SM by the number of SMs
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;

    // search limit
    const u64 workingThreads = file_size - target_string_len + 1;

    cudaMemcpyToSymbol(d_totalThreads, &workingThreads, sizeof(u64)); //CHECK
    
}


__global__ void parallelStringSearch(char* file_buffer, u64* occurrences){

    const u64 block_start = (u64)blockDim.x * blockIdx.x; // work start index 
    const u64 global_id = threadIdx.x + block_start; // thread id

    u32 block_pos = threadIdx.x; // thread id in the block

    const u64 stride = (u64)blockDim.x * gridDim.x;
    
    u64 my_occurrences = 0;

    extern __shared__ char shared_buffer[];

    __shared__ u64 shared_occurrences;

    if(block_pos == 0)
        shared_occurrences = 0;

    u64 numPrelievi = blockDim.x + d_target_string_len - 1;
    u64 prelieviLeft;
    u64 thisPrelievi;

    for(u64 k = global_id, blk = block_start; blk < d_totalThreads ; k += stride, blk += stride){

        prelieviLeft = d_file_size - blk;
        
        thisPrelievi = (numPrelievi < prelieviLeft) ? numPrelievi : prelieviLeft;

        for (u32 i = block_pos; i < (u32)thisPrelievi; i += blockDim.x) {
            shared_buffer[i] = file_buffer[blk + i];
        }


        __syncthreads();
        
        if(k < d_totalThreads){
            u32 i = 0;
            for(; i < d_target_string_len; i++){
                if(d_target_string[i] != shared_buffer[block_pos + i])
                break;
            }
            if(i == d_target_string_len)
                my_occurrences++;
        }

    __syncthreads();
        
    }

    if(my_occurrences > 0)
        atomicAdd(&shared_occurrences,my_occurrences);

    __syncthreads();

    if(block_pos == 0 && shared_occurrences > 0)
        atomicAdd(occurrences,shared_occurrences);
}

int main(int argc, char* argv[]);