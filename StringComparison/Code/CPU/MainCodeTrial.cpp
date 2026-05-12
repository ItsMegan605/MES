#include "shared.h"
#include "shared.cpp"

//the main is located in the shared.cpp file
int main(int argc, char* argv[]);

//function to chech if the chars match the target word
//returns the number of chars that match, if it is equal to the length of the target string then we have found an occurrence
unsigned long checkString(char* candidate_match, char* target, int target_len){

    unsigned long j;

    for(j = 0; j < target_len; j++){
        if(candidate_match[j] != target[j] || (candidate_match + target_len >= end_of_file)){
            break;
        }
    }

    return j;
}

//functon executed by every thread, analyzes a chunk of the file and counts the occurrences 
void findStringIstance(int thread_index, int remainder){

    unsigned long long file_position = thread_index * chunk_size;
    
    #ifdef DEBUG
    
        int local_occurrences = 0;
        chrono::steady_clock::time_point start = chrono::steady_clock::now();
    
    #endif
    int target_len = strlen(target_string);
    
    for(unsigned long long i = 0; i < chunk_size + remainder; i++){
        
        if(checkString(&file_buffer[file_position], target_string,target_len) == target_len){
            
            mtx.lock();
            occurrences++;
            mtx.unlock();
            
            #ifdef DEBUG

                local_occurrences++;
            
            #endif    
        }
        file_position++;

    }
    
    #ifdef DEBUG
    
        debug_print(thread_index, start, local_occurrences);
    
    #endif
}