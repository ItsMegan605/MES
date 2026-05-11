#include "shared.h"

// this file contains the code shared between all versions. implementation-specific
// functions will be declared here, and defined in the respective files

__global__ void parallelStringSearch(char* file_buffer, unsigned int* occurrences);

void implementationDependantManagement();


bool read_file_from_disk(){
    
    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Error: the file couldn't be opened.\n";
        return false;
    }
    
    file_buffer = new char[file_size];
    
    // we read one file block at the time, due to windows file size constraints
    
    std::uintmax_t bytes_left = file_size;
    char* buffer_offset = file_buffer;
    
    while(bytes_left){
        std::uintmax_t bytes_to_read = (bytes_left > max_read_size) ? max_read_size : bytes_left;
        
        file.read(buffer_offset, bytes_to_read);
        
        if(file.gcount() <= 0 || file.gcount() != bytes_to_read){
            cout <<"Error in file.read()"<< endl;
            delete[] file_buffer;   
            return false;
        }
        
        buffer_offset += bytes_to_read;
        bytes_left -= bytes_to_read;
    }
    
    file.close();
    
    return true;
}

void gpuMemoryInit(){

    int target_string_len = strlen(target_string);
    
    // global memory allocation
    cudaMalloc((void **) &d_file_buffer, file_size);
    cudaMalloc((void **) &d_occurrences, sizeof(unsigned int));

    // the file is copied from RAM to VRAM
    cudaMemcpy((void *)d_file_buffer, file_buffer, file_size, cudaMemcpyHostToDevice);

    // read-only values are copied into the read-only memory
    cudaMemcpyToSymbol(d_target_string, target_string, target_string_len);
    cudaMemcpyToSymbol(d_target_string_len, &target_string_len, sizeof(int));

    // is this implementation-specific?
    //cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(unsigned long long));

    // d_occurrences is set to 0
    cudaMemset((void *)d_occurrences, 0, sizeof(unsigned int));

}

int main(int argc, char* argv[]) {

    if (argc < MIN_INPUTS) {
        cout << "Insert the target string, the number of threads per block and (optional) a file limit expressed in MBs." << endl;
        return 1;
    }

    target_string = argv[TARGET_STRING]; //word to compare, taken from terminal
    threadsPerBlock = std::strtoull(argv[THREADS_PER_BLOCK], nullptr, 10); //number of threads per block, taken from terminal  

    if((threadsPerBlock & (32 - 1)) != 0){
        cout << "threadsPerBlock is not multiple of 32! Aborting..." << endl;
        return -1;
    }

    try {

        file_size = fs::file_size(FILE_PATH);

    } catch (const fs::filesystem_error& e) {
        
        cerr << "Can't read the file: " << e.what() << '\n';
        return 1;
    }

    if(argc > MIN_INPUTS){
        std::uintmax_t file_limit = std::strtoull(argv[FILE_LIMIT], nullptr, 10)*1024*1024;
        file_size = (file_limit < file_size)? file_limit : file_size;
    }

    file_size = (file_size > MAX_VRAM) ? MAX_VRAM : file_size;

    #ifdef DEBUG

        cout<< "FILE SIZE: "<< file_size<<endl;
    
    #endif


    if(!read_file_from_disk()){
        return -1;
    }

    // we allocate and load all values into VRAM
    gpuMemoryInit();

    // threads and shared memory are managed depending on the implementation
    implementationDependantManagement();

    chrono::steady_clock::time_point start = chrono::steady_clock::now();
    
    parallelStringSearch<<<blocksPerGrid, threadsPerBlock, shared_memory_size>>>(d_file_buffer, d_occurrences);
    cudaDeviceSynchronize();

    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);

    #ifdef DEBUG
        unsigned int occurrences;

        cudaMemcpy((void*)&occurrences, d_occurrences,sizeof(unsigned int), cudaMemcpyDeviceToHost);
    
        cout<<"Occurrences: "<< occurrences <<endl;
        cout<<"Total duration: " << duration.count() / (double) 1000 << " s | Throughput: ";
    
        cudaFree((void*)d_occurrences);
    #endif
    
    cout << ((double)file_size / duration.count())* 1000 << endl;


    delete[] longest_prefix_suffix_array;
    delete[] file_buffer;

    cudaFree((void*)d_file_buffer);
    
    return 0;
    
}