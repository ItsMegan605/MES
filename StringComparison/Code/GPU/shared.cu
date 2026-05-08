#include "shared.h"


// this file contains all the code shared between the various versions, main included

void findStringIstance(int, int); // this function will be different depending on which program is run

void debug_print(int thread_index, chrono::steady_clock::time_point start, unsigned int local_occurrences, int chunks_taken = 1){

}
/*

void build_table(char* target_string, int len,  int* longest_prefix_suffix_array){

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
                // Retrocediamo all'ultimo prefisso valido
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
    */

__global__ void parallelStringSearch(char* file_buffer, char* target_string, unsigned int* target_string_len, unsigned int* occurrences){

    int id = threadIdx.x + blockDim.x * blockIdx.x;

}


int main(int argc, char* argv[]) {

    if (argc < 2) {
        cout << "Insert the target string and (optional) a file limit expressed in MBs." << endl;
        return 1;
    }

    std::uintmax_t file_size;

    char* target_string;

    //int* longest_prefix_suffix_array;

    target_string = argv[1]; //word to compare, taken from terminal
    //num_threads = stoi(argv[2]); //number of threads, taken from terminal  


    try {
        file_size = fs::file_size(FILE_PATH);

    } catch (const fs::filesystem_error& e) {
        
        cerr << "Can't read the file: " << e.what() << '\n';
        return 1;
    }

    if(argc > 2){
        std::uintmax_t file_limit = std::strtoull(argv[3], nullptr, 10)*1024*1024;
        file_size = (file_limit < file_size)? file_limit : file_size;
    }

    file_size = (file_size > MAX_VRAM) ? MAX_VRAM : file_size;

    #ifdef DEBUG

        cout<< "FILE SIZE: "<< file_size<<endl;
    
    #endif

    //chunk_size = file_size / num_threads; //static chunk size for each thread

    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Error: the file couldn't be opened.\n";
        return 1;
    }

    char* file_buffer = new char[file_size];
    char* end_of_file = file_buffer + file_size + 1;

    int target_string_len = strlen(target_string);



    cudaMalloc((void **) d_file_buffer, file_size);
    cudaMalloc((void **) d_target_string, target_string_len);
    cudaMalloc((void **) d_occurrences, sizeof(unsigned int));
    cudaMalloc((void **) d_target_sting_len, sizeof(unsigned int));
    cudaMalloc((void **) d_file_size, sizeof(unsigned long long)); // devo fare malloc su roba definita come const o shared?
    
    long threadsPerBlock = 128;
    long blocksPerGrid = (file_size - target_string_len + 1) / threadsPerBlock;

    // we read one file block at the time, due to windows file size constraints
    std::uintmax_t bytes_left = file_size;
    char* buffer_offset = file_buffer;

    while(bytes_left){
        std::uintmax_t bytes_to_read = (bytes_left > max_read_size) ? max_read_size : bytes_left;

        file.read(buffer_offset, bytes_to_read);
        if(file.gcount() <= 0 || file.gcount() != bytes_to_read) {
            cout <<"Error in file.read()"<< endl;
            delete[] file_buffer;
            return 0;
        }
        buffer_offset += bytes_to_read;
        bytes_left -= bytes_to_read;
    }

    cudaMemcpy((void *)d_file_buffer,file_buffer,file_size,cudaMemcpyHostToDevice);
    cudaMemcpy((void *)d_target_string,target_string,target_string_len,cudaMemcpyHostToDevice);

    // we build the lps array, used by the kmp string match algorythm
    //longest_prefix_suffix_array = new int[target_string_len];
    //build_table(target_string, target_string_len, longest_prefix_suffix_array);

    chrono::steady_clock::time_point start = chrono::steady_clock::now();
    
    parallelStringSearch<<<blocksPerGrid, threadsPerBlock>>>(d_file_buffer,d_target_string,d_target_sting_len, d_occurrences); //DA CAMBIARE
    
    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);

    unsigned int occurences;

    cudaMemcpy((void*)&occurences, d_occurrences,sizeof(unsigned int), cudaMemcpyDeviceToHost);
    
    #ifdef DEBUG
        cout<<"Occurrences: "<< occurences <<endl;
        cout<<"Total duration: " << duration.count() / (double) 1000 << " s | Throughput: ";
    
    #endif
    
    cout << ((double)file_size / duration.count())* 1000 << endl;

    //end of file
    //delete[] longest_prefix_suffix_array;
    delete[] file_buffer;

    cudaFree((void*)d_file_buffer);
    cudaFree((void*)d_target_sting_len);
    cudaFree((void*)d_occurrences);
    cudaFree((void*)d_target_string);
    
    return 0;
    
}