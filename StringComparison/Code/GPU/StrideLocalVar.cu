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
    int target_blocks = numBlocksPerSm; // debug
    
    //shared_memory_size = props.sharedMemPerMultiprocessor / numBlocksPerSm;
    shared_memory_size = (sharedMemLimit*1024) / numBlocksPerSm;
    // GEMINI: FORZA L'ALLINEAMENTO A 16 BYTE (Tronca ai 16 byte inferiori)
    shared_memory_size = shared_memory_size & ~15ULL;


    cout << "Blocchi per SM teorici: " << numBlocksPerSm << endl;
    cout << "Memoria Condivisa per Blocco: " << shared_memory_size  << " B" << endl;

    numBlocksPerSm *= 1; // numero di ondate

    // Interroghiamo gli attributi specifici del nostro kernel
    cudaFuncAttributes attr;
    cudaFuncGetAttributes(&attr, parallelStringSearch);

    cout << "--- INFO KERNEL ---" << endl;
    cout << "Registri usati per ogni thread: " << attr.numRegs << endl;
    cout << "Memoria condivisa statica per blocco: " << attr.sharedSizeBytes << " bytes" << endl;
    cout << "-------------------" << endl;
            
    // Calcoliamo la griglia totale
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;
    
    #ifdef MAX_OCCUPANCY

        // Chiediamo a CUDA quanti blocchi ci stanno con questa shared memory
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            parallelStringSearch, 
            threadsPerBlock, 
            shared_memory_size
        );  

        cout << "Blocchi per SM effettivi: " << numBlocksPerSm << endl;

    #endif

    //cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(u64));
    cudaMemcpyToSymbol(d_shared_memory_size, &shared_memory_size, sizeof(u64));

    // COSE DA TOGLIERE
    
    int max_smem_per_block_allowed = 0;

    // Partiamo da un'ipotesi molto alta (es. 16 KB a blocco) e scendiamo a step di 256 byte
    for (int smem_test = 100*1024; smem_test >= 0; smem_test -= 256) {
        int active_blocks;
        
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &active_blocks, 
            parallelStringSearch, 
            threadsPerBlock, 
            smem_test
        );

        // Appena CUDA ci conferma che a questa dimensione i 12 blocchi sopravvivono, ci fermiamo.
        if (active_blocks >= target_blocks) {
            max_smem_per_block_allowed = smem_test;
            break;
        }
    }

    // Ora calcoliamo l'overhead esatto
    int total_physical_smem = props.sharedMemPerMultiprocessor; // I tuoi ~100KB o 128KB fisici
    int max_usable_smem = max_smem_per_block_allowed * target_blocks;
    int driver_overhead = total_physical_smem - max_usable_smem;

    cout << "--- ANALISI OVERHEAD HARDWARE ---" << endl;
    cout << "Memoria fisica totale dell'SM: " << total_physical_smem << " bytes" << endl;
    cout << "Limite massimo consentito per blocco (per avere " << target_blocks << " blocchi): " 
        << max_smem_per_block_allowed << " bytes" << endl;
    cout << "Memoria utile totale per i "<< target_blocks <<" blocchi: " << max_usable_smem << " bytes (" << max_usable_smem / 1024 << " KB )" << endl;
    cout << "OVERHEAD (Spazio rubato da Driver/L1/Metadati): " << driver_overhead << " bytes (" 
        << driver_overhead / 1024.0 << " KB)" << endl;
    cout << "---------------------------------" << endl;

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