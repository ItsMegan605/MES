#define DEBUG // uncomment for debug output

#include <iostream>
#include <string>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <vector>
#include <thread>
#include <atomic>
#include <chrono>
#include <mutex>
#include <stdio.h>
#include <cuda_runtime.h>
//#include <windows.h>

#define FILE_PATH "../CPU/giant_file.txt"

#define MAX_VRAM (unsigned long long)8000*1024*1024 // in MByte
#define MAX_TARGET_STR 256

using namespace std;
namespace fs = std::filesystem;

//windows uses 32 bit values for file reading
const std::uintmax_t max_read_size = 2000LL* 1024*1024;


// constant GPU pointers
__constant__ char d_target_string[MAX_TARGET_STR];
__constant__ unsigned int d_target_string_len;
__constant__ unsigned long long  d_totalThreads;

__global__ void parallelStringSearch(char* file_buffer, unsigned int* occurrences){

    unsigned long long global_id = threadIdx.x + (unsigned long long)blockDim.x * blockIdx.x;
    int block_pos = threadIdx.x;
    int block_size = blockDim.x;
    
    extern __shared__ char shared_buffer[];

    if(global_id < d_totalThreads)
        shared_buffer[block_pos] = file_buffer[global_id];

    // gestire caso stringa_len - 1 > blocco ma stica
    if(block_pos < d_target_string_len - 1)
        shared_buffer[block_size + block_pos] = file_buffer[block_size + global_id];

    __syncthreads();

    int i = 0;
    for(; i < d_target_string_len; i++){
        if(d_target_string[i] != shared_buffer[block_pos + i])
            break;
    }
    

    if(i == d_target_string_len)
        atomicAdd(occurrences, 1);


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
        std::uintmax_t file_limit = std::strtoull(argv[2], nullptr, 10)*1024*1024;
        file_size = (file_limit < file_size)? file_limit : file_size;
    }

    file_size = (file_size > MAX_VRAM) ? MAX_VRAM : file_size;

    #ifdef DEBUG

        cout<< "FILE SIZE: "<< file_size<<endl;
    
    #endif

    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Error: the file couldn't be opened.\n";
        return 1;
    }

    char* file_buffer = new char[file_size];

    int target_string_len = strlen(target_string);

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

    // GPU pointers
    char* d_file_buffer;
    unsigned int* d_occurrences;
        
    cudaMalloc((void **) &d_file_buffer, file_size);
    cudaMalloc((void **) &d_occurrences, sizeof(unsigned int));
    
    unsigned long long threadsPerBlock = 128;
    unsigned long long startingPositions = file_size - target_string_len + 1; //1021
    unsigned long long blocksPerGrid = startingPositions / threadsPerBlock + ((startingPositions % threadsPerBlock > 0) ? 1: 0);

    size_t shared_memory_size = threadsPerBlock + target_string_len - 1; 


    cudaMemcpy((void *)d_file_buffer, file_buffer, file_size, cudaMemcpyHostToDevice);
    cudaMemcpyToSymbol(d_target_string, target_string, target_string_len);
    cudaMemcpyToSymbol(d_target_string_len, &target_string_len, sizeof(int));
    cudaMemcpyToSymbol(d_totalThreads, &startingPositions, sizeof(unsigned long long));


    
    cudaMemset((void *)d_occurrences,0,sizeof(unsigned int)); //OOO


    //we build the lps array, used by the kmp string match algorythm
    //longest_prefix_suffix_array = new int[target_string_len];
    //build_table(target_string, target_string_len, longest_prefix_suffix_array);

    chrono::steady_clock::time_point start = chrono::steady_clock::now();
    
    parallelStringSearch<<<blocksPerGrid, threadsPerBlock, shared_memory_size>>>(d_file_buffer, d_occurrences);
    cudaDeviceSynchronize();

    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);

    unsigned int occurrences;

    cudaMemcpy((void*)&occurrences, d_occurrences,sizeof(unsigned int), cudaMemcpyDeviceToHost);
    
    #ifdef DEBUG
    
        cout<<"Occurrences: "<< occurrences <<endl;
        cout<<"Total duration: " << duration.count() / (double) 1000 << " s | Throughput: ";
    
    #endif
    
    cout << ((double)file_size / duration.count())* 1000 << endl;

    //end of file
    //delete[] longest_prefix_suffix_array;
    delete[] file_buffer;

    cudaFree((void*)d_file_buffer);
    cudaFree((void*)d_occurrences);
    //cudaFree((void*)d_target_sting_len);
    //cudaFree((void*)d_target_string);
    
    return 0;
    
}