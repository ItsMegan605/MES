#include "shared.h"

#ifdef BENCHMARK

    #include "bench.cu"

#else

    #include "shared.cu"

#endif

//NB: le var con d sono la "copia" dei parametri CPU
__global__ void parallelStringSearch(char* file_buffer, u64* occurrences);

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);

    shared_memory_size = threadsPerBlock + target_string_len - 1;

    
    // Chiediamo a CUDA: "Dato il mio threadsPerBlock, quanti blocchi posso 
    // mettere al massimo in un singolo Streaming Multiprocessor (SM)?"

    #ifdef MAX_OCCUPANCY
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            parallelStringSearch, 
            threadsPerBlock, 
            shared_memory_size
        );  
    #endif

    // Calcoliamo la griglia totale moltiplicando i blocchi per SM per il numero di SM
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;

    // limite della ricerca
    const u64 workingThreads = file_size - target_string_len + 1;

    cudaMemcpyToSymbol(d_totalThreads, &workingThreads, sizeof(u64)); //CHECK

    /*
    cout << "--- IDENTIKIT HARDWARE DELLA GPU ---" << endl;
    cout << "Memoria Condivisa Totale per SM: " << props.sharedMemPerMultiprocessor / 1024 << " KB" << endl;
    cout << "Blocchi per SM: " << numBlocksPerSm << endl;
    cout << "Memoria Condivisa per Blocco: " << ( props.sharedMemPerMultiprocessor / 1024 ) / numBlocksPerSm<< " KB" << endl;
    cout << "Memoria Costante Totale: " << props.totalConstMem / 1024 << " KB" << endl;
    cout << "Memoria Condivisa MAX per singolo Blocco: " << props.sharedMemPerBlock / 1024 << " KB" << endl;
    cout << "Registri Totali per SM: " << props.regsPerMultiprocessor << endl;
    cout << "Registri MAX per singolo Blocco: " << props.regsPerBlock << endl;
    cout << "Numero di SM (Processori): " << props.multiProcessorCount << endl;
    cout << "------------------------------------" << endl;
    */
    
}


__global__ void parallelStringSearch(char* file_buffer, u64* occurrences){

    const u64 block_start = (u64)blockDim.x * blockIdx.x; //indice di inziio lavoro 
    const u64 global_id = threadIdx.x + block_start; //id dei thread

    u32 block_pos = threadIdx.x; //id del thread nel blocco

    //total thread in exe, tutti i thread esistenti per vedere che alti fanno
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

        // gestire caso stringa lunga o blocco piccolo
        prelieviLeft = d_file_size - blk;
        
        thisPrelievi = (numPrelievi < prelieviLeft) ? numPrelievi : prelieviLeft;

        for (u32 i = block_pos; i < (u32)thisPrelievi; i += blockDim.x) {
            shared_buffer[i] = file_buffer[blk + i];
        }

        /*
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
        
    */
    }
    /*
    if(my_occurrences > 0)
        atomicAdd(&shared_occurrences,my_occurrences);

    __syncthreads();

    if(block_pos == 0 && shared_occurrences > 0)
        atomicAdd(occurrences,shared_occurrences);
    */
}

int main(int argc, char* argv[]);