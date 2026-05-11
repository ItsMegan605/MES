#include "shared.h"
#include "shared.cu"


void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    totalThreads = file_size - target_string_len + 1;

    blocksPerGrid = totalThreads / threadsPerBlock + ((totalThreads % threadsPerBlock > 0) ? 1: 0);

    shared_memory_size = threadsPerBlock + target_string_len - 1; 

    cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(unsigned long long));

}



__global__ void parallelStringSearch(char* file_buffer, unsigned int* occurrences){

    unsigned long long global_id = threadIdx.x + (unsigned long long)blockDim.x * blockIdx.x;
    int block_pos = threadIdx.x;
    int block_size = blockDim.x;
    
    extern __shared__ char shared_buffer[];

    // ottimizzazione possibile: 
    // ci salviamo strlen in un registro, invece che
    // accedere sempre alla memoria read only
    // unsigned int target_len = d_target_string_len;
    // magari fai la stessa cosa anche per d_totalThreads

    // ATTENZIONE! qua abbiamo un problema! i thread che hanno
    // global id troppo alto, non fanno questo if, MA VANNO
    // COMUNQUE AVANTI!!! GRAVE ERRORE, ACCESSI OUT OF BOUNDS!
    // farli terminare prima, ma gestire anche il prelievo del file!!
    /*
        // soluzione mia:
        if(global_id < d_totalThreads + target_len - 1){
            // lettura... (in parallelo, con thread in eccesso di aiuto)
        }  
        __syncthreads();

        // imperativo terminare dopo la syncthreads, per
        // prevenire deadlock!! USARE MEGA IF!
        if(global_id >= d_totalThreads)
            return;

    */


    if(global_id < d_totalThreads)
        shared_buffer[block_pos] = file_buffer[global_id];

    // gestire caso stringa_len - 1 > blocco ma stica
    if(block_pos < d_target_string_len - 1)
        shared_buffer[block_size + block_pos] = file_buffer[block_size + global_id];

    __syncthreads();

    int i = 0;
    for(; i < d_target_string_len; i++){
        if(d_target_string[i] != shared_buffer[block_pos + i])
            break;
    }
    

    if(i == d_target_string_len)
        atomicAdd(occurrences, 1);

}

int main(int argc, char* argv[]);