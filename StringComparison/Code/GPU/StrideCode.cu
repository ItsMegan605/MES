#include "shared.h"
#include "shared.cu"

//NB: le var con d sono la "copia" dei parametri CPU

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);

    shared_memory_size = roundToFour(threadsPerBlock + target_string_len - 1);

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

    cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(u64));

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

    u64 block_start = (u64)blockDim.x * blockIdx.x; //indice di inziio lavoro 
    u64 global_id = threadIdx.x + block_start; //id dei thread

    u32 block_pos = threadIdx.x; //id del thread nel blocco
    u32 block_size = blockDim.x;
    //total thread in exe, tutti i thread esistenti per vedere che alti fanno
    u64 stride = (u64)blockDim.x * gridDim.x;
    
    u64 my_occurrences = 0;
    //max lim di ricerca 
    u64 workingThreads = d_file_size - d_target_string_len + 1;

    extern __shared__ char shared_buffer[];

    __shared__ u64 shared_occurrences;

    if(block_pos == 0)
        shared_occurrences = 0;
    
        //memory coalesced access: dati raggruppaty 8 byte alla volta 
    u32 * shared_buffer_long = (u32*)shared_buffer;

    u32 numPrelievi = roundToFour(block_size + d_target_string_len -1)/4;
    u32 prelieviLeft;
    u32 thisPrelievi;

    for(u64 k = global_id, blk = block_start; blk < d_file_size ; k += stride, blk += stride){

        // gestire caso stringa lunga o blocco piccolo
        prelieviLeft = roundToFour(d_file_size - blk)/4;
        
        thisPrelievi = (numPrelievi < prelieviLeft) ? numPrelievi : prelieviLeft;
        if(block_pos < thisPrelievi){
                shared_buffer_long[block_pos] = *(((u32*)(file_buffer + blk)) + block_pos);
        }

        // abbiamo durante il for un 4-way-bank conflict. chiede di leggere 4 byte per volta, in modo da renderlo
        // un 2 way conflict, inoltre controlliamo 4 byte per volta

        __syncthreads();
        
        if(k < workingThreads){
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