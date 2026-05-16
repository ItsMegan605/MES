#include "shared.h"
#include "shared.cu"

//NB: le var con d sono la "copia" dei parametri CPU

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);
    
    int numBlocksPerSm;
    
    // Chiediamo a CUDA quanti blocchi ci stanno con questa shared memory
    cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &numBlocksPerSm, 
        parallelStringSearch, 
        threadsPerBlock, 
        128 
    );  
    
    shared_memory_size = props.sharedMemPerBlock / numBlocksPerSm;
    cout << "Blocchi per SM: " << numBlocksPerSm << endl;
    cout << "Memoria Condivisa per Blocco: " << shared_memory_size / 1024 << " KB" << endl;
            
    // Calcoliamo la griglia totale
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;
    totalThreads = blocksPerGrid * threadsPerBlock;

    cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(u64));
    cudaMemcpyToSymbol(d_shared_memory_size, &shared_memory_size, sizeof(u32));
}


__global__ void parallelStringSearch(char* file_buffer, u64* occurrences){
    
    extern __shared__ char shared_buffer[];

    const u32 block_pos = threadIdx.x; // id del thread nel blocco
    const u32 block_size = blockDim.x;
    
    // Step calcolato per creare sovrapposizione tra i blocchi e non perdere
    // le parole che cadono a cavallo tra un chunk e l'altro.
    const u32 overlap = roundToEight(d_target_string_len - 1);
    const u64 chunk_step = d_shared_memory_size - overlap;
    const u64 block_jump = chunk_step * gridDim.x;
    
    u64 my_occurrences = 0;

    for(u64 startPrelievo = chunk_step * blockIdx.x; startPrelievo < d_file_size; startPrelievo += block_jump){
        
        // Evitiamo di leggere oltre la fine del file
        u64 limPrelievo = d_shared_memory_size; //vedo i byte ancora da trasf
        if(startPrelievo + limPrelievo > d_file_size) {
            limPrelievo = d_file_size - startPrelievo;
        }

        limPrelievo >>= 3;

        // gli accessi saranno sempre allineati a 4, qui cerco interi
        for(u64 thisPrelievo = block_pos; thisPrelievo < limPrelievo; thisPrelievo += block_size){
            ((long long*)shared_buffer)[thisPrelievo] = ((long long*)file_buffer)[(startPrelievo >> 3) + thisPrelievo];
        }

        __syncthreads();

        limPrelievo <<= 3; 
        if(limPrelievo >= d_target_string_len){
            
            for(u64 startSearch = block_pos; startSearch <= limPrelievo - overlap - 1; startSearch += block_size){
                int i = 0;
                for(; i < d_target_string_len ; i++){ //confronto per la string
                    if(shared_buffer[startSearch + i] != d_target_string[i])
                        break; 
                }
                if(i == d_target_string_len)
                    my_occurrences++; // se trovo occorrenza
            }
        }
        
        __syncthreads();
    }

    u64 * shared_occurrences = (u64*)shared_buffer;
    
    if(block_pos == 0) {
        *shared_occurrences = 0;
    }
    
    __syncthreads(); 
    
    if(my_occurrences > 0) {
        atomicAdd(shared_occurrences, my_occurrences);
    }
    
    __syncthreads(); 
    
    if(block_pos == 0 && *shared_occurrences > 0) {
        atomicAdd(occurrences, *shared_occurrences);
    }
}