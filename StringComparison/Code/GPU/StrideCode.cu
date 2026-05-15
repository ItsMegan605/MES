#include "shared.h"
#include "shared.cu"

//NB: le var con d sono la "copia" dei parametri CPU

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);

    shared_memory_size = roundToEight(threadsPerBlock + target_string_len - 1);

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

    unsigned long long block_start = (unsigned long long)blockDim.x * blockIdx.x; //indice di inziio lavoro 
    unsigned long long global_id = threadIdx.x + block_start; //id dei thread

    unsigned int block_pos = threadIdx.x; //id del thread nel blocco
    unsigned int block_size = blockDim.x;
    //total thread in exe, tutti i thread esistenti per vedere che alti fanno
    unsigned long long stride = (unsigned long long)blockDim.x * gridDim.x;
    
    unsigned long long my_occurrences = 0;
    //max lim di ricerca 
    unsigned long long workingThreads = d_file_size - d_target_string_len + 1;

    extern __shared__ char shared_buffer[];

    __shared__ unsigned long long shared_occurrences;

    if(block_pos == 0)
        shared_occurrences = 0;
    
        //memory coalesced access: dati raggruppaty 8 byte alla volta 
    unsigned long long * shared_buffer_long = (unsigned long long*)shared_buffer;

    unsigned int numPrelievi = roundToEight(block_size + d_target_string_len -1)/8;
    unsigned int prelieviLeft;
    unsigned int thisPrelievi;

    for(unsigned long long k = global_id, blk = block_start; blk < d_file_size ; k += stride, blk += stride){

        // gestire caso stringa lunga o blocco piccolo
        prelieviLeft = roundToEight(d_file_size - blk)/8;
        
        thisPrelievi = (numPrelievi < prelieviLeft) ? numPrelievi : prelieviLeft;
        if(block_pos < thisPrelievi){
                shared_buffer_long[block_pos] = *(((unsigned long long*)(file_buffer + blk)) + block_pos);
        }

        // GEMINI DICE: abbiamo durante il for un 4-way-bank conflict. chiede di leggere 4 byte per volta, in modo da renderlo
        // un 2 way conflict, inoltre controlliamo 4 byte per volta

        __syncthreads();
        
        if(k < workingThreads){
            unsigned int i = 0;
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