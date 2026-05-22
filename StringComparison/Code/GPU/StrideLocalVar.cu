#include "shared.h"

#ifdef BENCHMARK

    #include "bench.cu"

#else

    #include "shared.cu"

#endif

#ifndef VARS

    #define TYPE u64
    #define EXP 3
    #define ROUND roundToEight

#endif
//NB: le var con d sono la "copia" dei parametri CPU

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);
    
    #ifdef MAX_OCCUPANCY

        // Chiediamo a CUDA quanti blocchi ci stanno con questa shared memory
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            parallelStringSearch, 
            threadsPerBlock, 
            128 
        );  

    #endif
    
    shared_memory_size = props.sharedMemPerBlock / numBlocksPerSm;
    
    // GEMINI: FORZA L'ALLINEAMENTO A 16 BYTE (Tronca ai 16 byte inferiori)
    shared_memory_size = shared_memory_size & ~15ULL;

    cout << "Blocchi per SM: " << numBlocksPerSm << endl;
    cout << "Memoria Condivisa per Blocco: " << shared_memory_size / 1024 << " KB" << endl;

    // Interroghiamo gli attributi specifici del nostro kernel
    cudaFuncAttributes attr;
    cudaFuncGetAttributes(&attr, parallelStringSearch);

    cout << "--- INFO KERNEL ---" << endl;
    cout << "Registri usati per ogni thread: " << attr.numRegs << endl;
    cout << "Memoria condivisa statica per blocco: " << attr.sharedSizeBytes << " bytes" << endl;
    cout << "-------------------" << endl;
            
    // Calcoliamo la griglia totale
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;
    //u64 totalThreads = blocksPerGrid * threadsPerBlock;

    //cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(u64));
    cudaMemcpyToSymbol(d_shared_memory_size, &shared_memory_size, sizeof(u64));
}


__global__ void parallelStringSearch(char* file_buffer, u64* occurrences){
    
    extern __shared__ char shared_buffer[];

    const u32 block_pos = threadIdx.x; // id del thread nel blocco
    
    // GEMINI DICE: Poiché d_shared_memory_size è multiplo di 16 e d_target_string_len 
    // viene arrotondato a 16, chunk_step sarà SEMPRE multiplo di 16.
    // Di conseguenza, startPrelievo sarà sempre perfettamente allineato!

    // Step calcolato per creare sovrapposizione tra i blocchi e non perdere
    // le parole che cadono a cavallo tra un chunk e l'altro.
    const u32 overlap = ROUND(d_target_string_len - 1);
    const u64 chunk_step = d_shared_memory_size - overlap;
    const u64 block_jump = chunk_step * gridDim.x;
    
    u32 my_occurrences = 0; // gemini dice sia piu veloce un registro a 4 byte

    for(u64 startPrelievo = chunk_step * blockIdx.x; startPrelievo < d_file_size; startPrelievo += block_jump){
        
        // Evitiamo di leggere oltre la fine del file
        u64 limPrelievo = d_shared_memory_size; //vedo i byte ancora da trasf
        bool is_last_block = false;

        if(startPrelievo + limPrelievo > d_file_size) {
            limPrelievo = d_file_size - startPrelievo;
            is_last_block = true;
        }

        u64 limPrelievoLarge = ROUND(limPrelievo) >> EXP;
        u64 startPrelievoLarge = ROUND(startPrelievo) >> EXP;

        // gli accessi saranno sempre allineati a 4, qui cerco TYPE
        for(u64 thisPrelievo = block_pos; thisPrelievo < limPrelievoLarge; thisPrelievo += blockDim.x){
            ((TYPE*)shared_buffer)[thisPrelievo] = ((TYPE*)file_buffer)[(startPrelievoLarge) + thisPrelievo];
        }

        __syncthreads();

        if(limPrelievo >= d_target_string_len){
            u64 searchLimit;
            if(is_last_block)
                searchLimit = limPrelievo - d_target_string_len;
            else
                searchLimit = limPrelievo - overlap - 1;
            for(u64 startSearch = block_pos; startSearch <= searchLimit; startSearch += blockDim.x){
                u32 i = 0;
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