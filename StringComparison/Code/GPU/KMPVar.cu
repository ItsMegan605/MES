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

void build_table(int len){

    longest_prefix_suffix_array = new int[len];

    char * head, *tail;
    head = tail = target_string;
    
    
    longest_prefix_suffix_array[0]=0; // the first element is always 0, therefore ...
    tail++; // ... we start from the second element
    int pos = 0;

    for(int i = 1; i < len; i++){

        if(*tail == *head){
            pos++;
            longest_prefix_suffix_array[i] = pos;
            head++;
        }else{
            if (pos != 0) {
                // we go back to the first valid prefix
                pos = longest_prefix_suffix_array[pos - 1];
                head = target_string + pos;
            
                i--;    
                tail--; 
            } else {
                longest_prefix_suffix_array[i] = 0;
            }
        }
        tail++;
    }

    #ifdef DEBUG
        cout<<"LPS: [ ";
        for(int i = 0; i < len; i++){
            cout<<longest_prefix_suffix_array[i];
            if(i != len - 1) 
                cout<<", ";
        }

            cout<<"]"<<endl;
    #endif 

}

void implementationDependantManagement(){

    const int target_string_len = strlen(target_string);
    
    //we build the lps array, used by the kmp string match algorythm
    build_table(target_string_len);

    cudaMemcpyToSymbol(d_longest_prefix_suffix_array, longest_prefix_suffix_array, target_string_len * sizeof(int), cudaMemcpyHostToDevice);

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
    //u64 totalThreads = blocksPerGrid * threadsPerBlock;
    

    const u64 chunk_step = shared_memory_size - target_string_len + 1;
    
    // GEMINI: Dividiamo solo lo spazio utile (chunk_step) tra i thread
    const u64 memory_for_thread = (chunk_step + threadsPerBlock - 1) / threadsPerBlock;

    // memory for each thread (sbagliato perche ragioniamo in chunk non in shared memory)
    //const u64 memory_for_thread = shared_memory_size / threadsPerBlock;
    
    cout << "Memoria per singolo thread: " << memory_for_thread << " B" << endl;


    cudaMemcpyToSymbol(d_memory_for_thread, &memory_for_thread, sizeof(u64));

    cudaMemcpyToSymbol(d_chunk_step, &chunk_step, sizeof(u64));

    //cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(u64));
    cudaMemcpyToSymbol(d_shared_memory_size, &shared_memory_size, sizeof(u64));

}


__global__ void parallelStringSearch(char* file_buffer, u64* occurrences){

    //const u64 global_id = threadIdx.x + (u64)blockDim.x * blockIdx.x;
    
    extern __shared__ char shared_buffer[];

    const u32 block_pos = threadIdx.x; // id del thread nel blocco


    //const u64 chunk_step = d_shared_memory_size - d_target_string_len + 1;
    const u64 block_jump = d_chunk_step * gridDim.x;
    
    u64 my_occurrences = 0;

    // problema: current shared va a dimensione di memoria shared,
    //const u32 last_shared = (d_file_size / d_shared_memory_size) - 1 + (((d_file_size % d_shared_memory_size > 0)) ? 1 : 0);
    //u32 current_shared = blockIdx.x;


    for(u64 startPrelievo = d_chunk_step * blockIdx.x; startPrelievo < d_file_size; startPrelievo += block_jump){

        
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

        if(limPrelievo >= d_target_string_len) {

            u64 startSearch = block_pos * d_memory_for_thread;
            u64 file_remainder = d_file_size - (startPrelievo + startSearch);

            if(file_remainder > 0 && startSearch < d_chunk_step){

                // tumore
                u32 search_end = startSearch;
                u32 search_limit = 0;

                //GEMINI
                // Quanti byte "normali" spettano a questo thread?
                // Prende d_memory_for_thread, a meno che non sbatta contro d_chunk_step o la fine del file
                u64 valid_thread_bytes = d_memory_for_thread;
                if (startSearch + valid_thread_bytes > d_chunk_step) {
                    valid_thread_bytes = d_chunk_step - startSearch;
                }

                if (file_remainder <= valid_thread_bytes) {
                    // Siamo all'ultimissimo pezzo del file, niente extra field
                    search_end += file_remainder;
                } else {
                    // Caso normale: limitiamo la ricerca normale e calcoliamo l'extra
                    search_end += valid_thread_bytes;
                    u64 remaining_after_end = file_remainder - valid_thread_bytes;
                    search_limit = (d_target_string_len - 1 < remaining_after_end) ? (d_target_string_len - 1) : remaining_after_end;
                }
                // FIN QUA

                search_limit += search_end;

                u32 target_index = 0, candidate_index = startSearch;

                while(candidate_index < search_limit){ //ogni thread prende peszo di memoria shared

                    if (candidate_index >= search_end && target_index == 0)
                        break;
                    
                    if(d_target_string[target_index] == shared_buffer[candidate_index]){
                        target_index++;
                        candidate_index++;
                        
                        if(target_index == d_target_string_len){
                            my_occurrences++;
                            target_index = d_longest_prefix_suffix_array[target_index - 1];
                        }
                    }else{
                        if(target_index != 0)
                            target_index = d_longest_prefix_suffix_array[target_index - 1];
                        else{
                            candidate_index++;
                        }
                    }
                }
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