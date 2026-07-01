#include "shared.h"
#include <vector>
#include <string>
#include <fstream>
#include <iomanip>
#include <locale>

void implementationDependantManagement();
__global__ void parallelStringSearch(char* file_buffer, u64* occurrences);

template <typename T>
__host__ __device__ inline T roundToFour(T value){
    return (value + 3) & ~ (T)3;
}

template <typename T>
__host__ __device__ inline T roundToEight(T value){
    return (value + 7) & ~ (T)7;
}

template <typename T>
__host__ __device__ inline T roundToSixteen(T value){
    return (value + 15) & ~ (T)15;
}

bool read_file_from_disk(){
    
    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Error: the file couldn't be opened.\n";
        return false;
    }
    
    file_buffer = new char[file_size];
    
    // we read one file block at the time, due to windows file size constraints
    u64 bytes_left = file_size;
    char* buffer_offset = file_buffer;
    
    while(bytes_left){
        u64 bytes_to_read = (bytes_left > max_read_size) ? max_read_size : bytes_left;
        
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

// excel garbage
struct comma_facet : std::numpunct<char> {
    char do_decimal_point() const override { return ','; }
};

int main(int argc, char* argv[]) {

    if(argc != 2){
        cout<<"provide the .csv file name"<<endl;
    }

    
    char * output_file = new char[strlen("csv/")+ strlen(argv[1]) + strlen(".csv") + 1]; // + .csv + \0
    strcpy(output_file,"csv/");
    strcpy(output_file + strlen("csv/") ,argv[1]);
    strcpy(output_file + strlen("csv/") + strlen(argv[1]), ".csv");

    std::vector<std::string> strings = {"unevenstring"};
    std::vector<u64> file_sizes_mb = {4000};
    
    std::vector<u32> shared_mem_limits = {99}; 
   // std::vector<u64> threads = {32, 64, 96, 128, 160, 192, 224, 256, 288};
    std::vector<u64> threads = {96};
    std::vector<int> nblocks = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}; 

    
    const int runs = 30;

    std::ofstream csv(output_file);
    if (!csv) {
        cerr << "Error: unable to create <<"<< output_file<<endl;
        return 1;
    }
    csv.imbue(std::locale(csv.getloc(), new comma_facet()));
    csv << "stringa cercata;limite shared mem;thread per blocco;blocchi per SM;ripetizione;dimensione file;throughput\n";

    u64 actual_file_size;
    try {
        actual_file_size = fs::file_size(FILE_PATH);
    } catch (const fs::filesystem_error& e) {
        cerr << "Can't read the file: " << e.what() << '\n';
        return 1;
    }
    
    file_size = actual_file_size;
    if(!read_file_from_disk()){
        return -1;
    }

    cout << "Loading file into VRAM..." << endl;
    cudaMalloc((void **) &d_file_buffer, roundToSixteen(actual_file_size));
    cudaMalloc((void **) &d_occurrences, sizeof(u64));
    cudaMemcpy((void *)d_file_buffer, file_buffer, actual_file_size, cudaMemcpyHostToDevice);
    cout << "File in VRAM. Starting benchmark loops..." << endl;

    for(u64 fs_mb : file_sizes_mb) {
        
        u64 current_file_size_bytes = fs_mb * 1024 * 1024;
        if(current_file_size_bytes > actual_file_size) current_file_size_bytes = actual_file_size;
        if(current_file_size_bytes > MAX_VRAM) current_file_size_bytes = MAX_VRAM;
        
        file_size = current_file_size_bytes; 
        cudaMemcpyToSymbol(d_file_size, &file_size, sizeof(u64));

        for(const std::string& str : strings) {
            
            target_string = (char*)str.c_str();
            int target_string_len = str.length();
            
            cudaMemcpyToSymbol(d_target_string, target_string, target_string_len);
            cudaMemcpyToSymbol(d_target_string_len, &target_string_len, sizeof(int));

            for(u32 sm_limit : shared_mem_limits) {
                sharedMemLimit = sm_limit;

                for(u64 t : threads) {
                    threadsPerBlock = t;
                    
                    for(int b : nblocks) {
                        numBlocksPerSm = b;
                
                        implementationDependantManagement(); 
                        
                        for(int r = 1; r <= runs; r++) {
                            
                            cudaMemset((void *)d_occurrences, 0, sizeof(u64));
                            cudaDeviceSynchronize();

                            auto start = std::chrono::steady_clock::now();
                            
                            parallelStringSearch<<<blocksPerGrid, threadsPerBlock, shared_memory_size>>>(d_file_buffer, d_occurrences);
                            cudaDeviceSynchronize();

                            auto end = std::chrono::steady_clock::now();
                            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

                            double throughput = ((double)file_size / duration.count()) * 1000.0;

                            csv << str << ";" 
                                << sharedMemLimit << ";"
                                << threadsPerBlock << ";" 
                                << numBlocksPerSm << ";" 
                                << r << ";" 
                                << fs_mb << ";" 
                                << std::fixed << std::setprecision(2) << throughput << "\n";
                            
                            // Stampa a schermo
                            cout << "Completed Run " << r << "/" << runs 
                                << " | Str: " << str
                                << " | SM Limit: " << sharedMemLimit
                                << " | Thr: " << threadsPerBlock 
                                << " | Blocks: " << numBlocksPerSm 
                                << " | Size: " << fs_mb 
                                << "MB | Throughput: " << throughput << endl;
                        }
                    }
                }
            }
        }
    }

    csv.close();
    delete[] output_file;
    delete[] file_buffer;
    cudaFree((void*)d_file_buffer);
    cudaFree((void*)d_occurrences);
    if(longest_prefix_suffix_array) delete[] longest_prefix_suffix_array;
    
    cout << "\nBOOM! Benchmark completed successfully. Results saved in " << argv[1] << ".csv" << endl;
    return 0;
}