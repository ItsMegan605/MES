#include "shared.h"
#include "shared.cpp"


//the main is located in the shared.cpp file
int main(int argc, char* argv[]);

uintmax_t getNewChunk(){
    lock_guard<mutex> lk(chunk_mtx);
    uintmax_t current_start = next_chunk_size;
    next_chunk_size += CHUNK_SIZE;

    return current_start;
}

void findStringIstance(int thread_index, int){

    uintmax_t current_chunk_start = getNewChunk();
    long long bytes_left = (file_size - current_chunk_start < CHUNK_SIZE) ? file_size - current_chunk_start : CHUNK_SIZE;

    int target_string_length = strlen(target_string);

    unsigned long target_index = 0, candidate_index = current_chunk_start;
    int local_occurrences = 0;

    int extra_search_field = (file_size - current_chunk_start < CHUNK_SIZE) ? 0 : target_string_length - 1;
    
    #ifdef DEBUG
    
        chrono::steady_clock::time_point start = chrono::steady_clock::now();
        int chunks_taken = 0;
    
    #endif
    
    while(current_chunk_start < file_size){

        #ifdef DEBUG

            chunks_taken++;

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
        
        current_chunk_start = getNewChunk();
        target_index = 0;
        candidate_index = current_chunk_start;

        if(file_size - current_chunk_start <= CHUNK_SIZE){
            bytes_left = file_size - current_chunk_start;
            extra_search_field = 0;
        } else {
            bytes_left = CHUNK_SIZE;
            extra_search_field = target_string_length - 1;
        }

    }
    atomic_occurrences+=local_occurrences;

    #ifdef DEBUG
    
        debug_print(thread_index, start, local_occurrences,chunks_taken);
    
    #endif
}
