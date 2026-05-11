#include "shared.h"
#include "shared.cu"

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

    int target_string_len = strlen(target_string);
    
    //we build the lps array, used by the kmp string match algorythm
    build_table(target_string_len);

    cudaMemcpyToSymbol(d_longest_prefix_suffix_array, longest_prefix_suffix_array, target_string_len * sizeof(int), cudaMemcpyHostToDevice);
    // totalThreads = ...


}


__global__ void parallelStringSearch(char* file_buffer, unsigned int* occurrences){

    unsigned long long global_id = threadIdx.x + (unsigned long long)blockDim.x * blockIdx.x;
    int block_pos = threadIdx.x;
    int block_size = blockDim.x;
    
    extern __shared__ char shared_buffer[];

    // ... to be continued
}
