#include "shared.h"
#include "shared.cpp"

//the main is located in the shared.cpp file

void findStringIstance(int thread_index, int remainder){

    const int target_string_length = strlen(target_string);

    u64 target_index = 0, candidate_index = thread_index * chunk_size;
    int local_occurrences = 0;

    const u64 search_end = candidate_index + chunk_size + remainder;
    const u64 search_limit = search_end + min((u64)(target_string_length -1), file_size - search_end);

    #ifdef DEBUG
    
        chrono::steady_clock::time_point start = chrono::steady_clock::now();
    
    #endif

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
    atomic_occurrences += local_occurrences;

    #ifdef DEBUG
    
        debug_print(thread_index, start, local_occurrences);
    
    #endif

}
