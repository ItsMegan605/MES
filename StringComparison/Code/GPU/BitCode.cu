#include "shared.h"
#include "shared.cu"



void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);

    shared_memory_size = ((threadsPerBlock + target_string_len - 1) + 8) & ~7;

    // Chiediamo a CUDA: "Dato il mio threadsPerBlock, quanti blocchi posso 
    // mettere al massimo in un singolo Streaming Multiprocessor (SM)?"
    int numBlocksPerSm;
    cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &numBlocksPerSm, 
        parallelStringSearch, 
        threadsPerBlock, 
        shared_memory_size
    );  

    // Calcoliamo la griglia totale moltiplicando i blocchi per SM per il numero di SM
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;

    // totalThreads a questo punto è semplice:
    totalThreads = blocksPerGrid * threadsPerBlock;

    cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(unsigned long long));

}


__global__ void parallelStringSearch(char* file_buffer, unsigned long long* occurrences){

    unsigned long long block_start = (unsigned long long)blockDim.x * blockIdx.x;
    unsigned long long global_id = threadIdx.x + block_start;
    int block_pos = threadIdx.x;
    int block_size = blockDim.x;
    unsigned long long stride = (unsigned long long)blockDim.x * gridDim.x;
    
    unsigned long long my_occurrences = 0;

    unsigned long long workingThreads = d_file_size - d_target_string_len + 1;

    extern __shared__ char shared_buffer[];

    __shared__ unsigned long long shared_occurrences;
    
    unsigned long long * shared_buffer_long = (unsigned long long*)shared_buffer;

    int numPrelievi = ((block_size + d_target_string_len -1 + 8) & ~7) / 8;


    for(unsigned long long k = global_id, blk = block_start; blk < d_file_size ; k += stride, blk += stride){
        /*
        if(k < d_file_size){

            shared_buffer[block_pos] = file_buffer[k];
            
            // gestire caso stringa_len - 1 > blocco ma stica
            if((block_pos < d_target_string_len - 1)  && (k + block_size < d_file_size))
                shared_buffer[block_size + block_pos] = file_buffer[block_size + k];
        }
                */

                // gestire caso stringa lunga o blocco piccolo
       if(block_pos < numPrelievi){
            shared_buffer_long[block_pos] = *(((unsigned long long*)&file_buffer[block_start]) + (8*block_pos));
       }


        __syncthreads();
        
        if(k < workingThreads){
            int i = 0;
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