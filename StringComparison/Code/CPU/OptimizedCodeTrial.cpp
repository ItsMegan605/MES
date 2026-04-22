#include "shared.h"
#include "shared.cpp"

//the main is located in the shared.cpp file
int main(int argc, char* argv[]);

void findStringIstance(int thread_index, int remainder){

    int target_string_length = strlen(target_string);

    unsigned long target_index = 0, candidate_index = thread_index * chunk_size;
    int local_occurrences = 0;

    long long bytes_left = chunk_size + remainder;
    int extra_search_field = (candidate_index + chunk_size + remainder >= file_size) ? 0 : target_string_length - 1;

    #ifdef DEBUG
    
        chrono::steady_clock::time_point start = chrono::steady_clock::now();
    
    #endif

    while(true){
        if(bytes_left <= 0){
            if(target_index != 0){
                extra_search_field--;
                if(extra_search_field < 0)
                    break;
            }else
                break;
        }
        
        if(target_string[target_index] == file_buffer[candidate_index]){
            target_index++;
            candidate_index++;
            bytes_left--;
            
            if(target_index == target_string_length){
                local_occurrences++;
                target_index = longest_prefix_suffix_array[target_index - 1];
            }
        }else{
            if(target_index != 0)
                target_index = longest_prefix_suffix_array[target_index - 1];
            else{
                candidate_index++;
                bytes_left--;
            }
        }
    }
    atomic_occurrences += local_occurrences;

    #ifdef DEBUG
    
        debug_print(thread_index, start, local_occurrences);
    
    #endif

}
