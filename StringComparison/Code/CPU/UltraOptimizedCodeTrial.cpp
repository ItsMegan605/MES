#include "shared.h"
#include "shared.cpp"


//the main is located in the shared.cpp file


uintmax_t getNewChunk(){
    lock_guard<mutex> lk(chunk_mtx);
    uintmax_t current_start = next_chunk_size;
    next_chunk_size += CHUNK_SIZE;

    return current_start;
}

void findStringIstance(int thread_index, int){
    
    const int target_string_length = strlen(target_string);
    
    u64 current_chunk_start;

    u64 valid_interval;
    u64 search_end, search_limit;

    u64 target_index, candidate_index;

    int local_occurrences = 0;

    #ifdef DEBUG
    
        chrono::steady_clock::time_point start = chrono::steady_clock::now();
        int chunks_taken = 0;
    
    #endif
    
    while(true){

        current_chunk_start = getNewChunk();

        if(current_chunk_start >= file_size)
            break;
                
        #ifdef DEBUG
            
            chunks_taken++;
            
        #endif

        target_index = 0;
        candidate_index = current_chunk_start;
        
        valid_interval = file_size - current_chunk_start;
        search_end = current_chunk_start + ((valid_interval < CHUNK_SIZE) ? valid_interval : CHUNK_SIZE);
        search_limit = search_end + min((u64)(target_string_length - 1), file_size - search_end);

        while(candidate_index < search_limit){

            if(candidate_index >= search_end && target_index == 0)
                break;

            if(target_string[target_index] == file_buffer[candidate_index]){
                target_index++;
                candidate_index++;

                if(target_index == target_string_length){
                    local_occurrences++;
                    target_index = longest_prefix_suffix_array[target_index - 1];
                }
            }else{
                if(target_index != 0)
                    target_index = longest_prefix_suffix_array[target_index - 1];
                else
                    candidate_index++;
            }
        }
    }
    atomic_occurrences += local_occurrences;

    #ifdef DEBUG
    
        debug_print(thread_index, start, local_occurrences,chunks_taken);
    
    #endif
}
