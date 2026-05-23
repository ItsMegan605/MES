#include "shared.h"
#include <vector>
#include <string>
#include <fstream>
#include <iomanip>
#include <locale>


// Funzioni preesistenti (le assumiamo incluse via shared.cu/h)
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



// Hack per forzare la virgola per i decimali invece del punto (per Excel in Italiano)
struct comma_facet : std::numpunct<char> {
    char do_decimal_point() const override { return ','; }
};

int main(int argc, char* argv[]) {

    if(argc != 2){
        cout<<"metti il nome del file .csv"<<endl;
    }

    char * output_file = new char[strlen(argv[1]) + 5]; // + .csv + \0
    strcpy(output_file,argv[1]);
    strcpy(output_file + strlen(argv[1]), ".csv");

    // 1. Setup Configurazioni del Benchmark
    std::vector<std::string> strings = { "abracadabra"};//{"abracadabra", "unevenstring", "------------"};
    std::vector<u64> threads = {32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416};
    std::vector<int> nblocks = {24};
    std::vector<u64> file_sizes_mb = {7000};

    const int runs = 30; // MI SE CAMBI

    // 2. Setup del file CSV
    std::ofstream csv(output_file);
    if (!csv) {
        cerr << "Errore: impossibile creare benchmark_results.csv\n";
        return 1;
    }
    // Applica la formattazione italiana (virgola per i decimali)
    csv.imbue(std::locale(csv.getloc(), new comma_facet()));
    csv << "stringa cercata;thread per blocco;ripetizione;dimensione file;throughput\n";

    // 3. Lettura del file originale da disco (FATTA UNA SOLA VOLTA)
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

    // 4. Allocazione globale in VRAM (FATTA UNA SOLA VOLTA)
    cout << "Caricamento file in VRAM in corso..." << endl;
    cudaMalloc((void **) &d_file_buffer, roundToSixteen(actual_file_size));
    cudaMalloc((void **) &d_occurrences, sizeof(u64));
    cudaMemcpy((void *)d_file_buffer, file_buffer, actual_file_size, cudaMemcpyHostToDevice);
    cout << "File in VRAM. Inizio i loop del benchmark..." << endl;

    // 5. Inizio dei nested loop per il benchmark
    for(u64 fs_mb : file_sizes_mb) {
        
        // Calcola e limita la dimensione "virtuale"
        u64 current_file_size_bytes = fs_mb * 1024 * 1024;
        if(current_file_size_bytes > actual_file_size) current_file_size_bytes = actual_file_size;
        if(current_file_size_bytes > MAX_VRAM) current_file_size_bytes = MAX_VRAM;
        
        // Aggiorna variabile globale e memoria costante della GPU
        file_size = current_file_size_bytes; 
        cudaMemcpyToSymbol(d_file_size, &file_size, sizeof(u64));

        for(const std::string& str : strings) {
            
            // Aggiorna la stringa puntata globalmente per implementationDependantManagement()
            target_string = (char*)str.c_str();
            int target_string_len = str.length();
            
            cudaMemcpyToSymbol(d_target_string, target_string, target_string_len);
            cudaMemcpyToSymbol(d_target_string_len, &target_string_len, sizeof(int));

            #ifdef MAX_OCCUPANCY
            for(u64 t : threads) {
                threadsPerBlock = t;
            #else 

                threadsPerBlock = threads[0];
            for(int b : nblocks) {
                numBlocksPerSm = b;
            
            #endif
                // Calcola gridDim e shared_memory in base ai nuovi threadsPerBlock
                implementationDependantManagement(); 
                
                for(int r = 1; r <= runs; r++) {
                    
                    // Reset delle occorrenze a 0 per la nuova run
                    cudaMemset((void *)d_occurrences, 0, sizeof(u64));
                    cudaDeviceSynchronize();

                    auto start = std::chrono::steady_clock::now();
                    
                    // Lancio del kernel
                    parallelStringSearch<<<blocksPerGrid, threadsPerBlock, shared_memory_size>>>(d_file_buffer, d_occurrences);
                    cudaDeviceSynchronize();

                    auto end = std::chrono::steady_clock::now();
                    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

                    // Calcolo Throughput (Bytes per second, convertibile in MB/s a piacimento)
                    double throughput = ((double)file_size / duration.count()) * 1000.0;

                    // Salvataggio nel file CSV
                    csv << str << ";" 
                        #ifdef MAX_OCCUPANCY
                            << threadsPerBlock << ";" 
                        #else
                            << numBlocksPerSm << ";" 
                        #endif
                        << r << ";" 
                        << fs_mb << ";" 
                        << std::fixed << std::setprecision(2) << throughput << "\n";
                    
                    // Stampa a schermo per farti vedere che è vivo
                    cout << "Completata Run " << r << "/30 | Str: " << str
                        #ifdef MAX_OCCUPANCY 
                            << " | Thr: " << threadsPerBlock 
                         #else
                            << " | blocchi: " << numBlocksPerSm 
                         #endif
                         << " | Size: " << fs_mb 
                         << "MB | Throughput: " << throughput << endl;
                }
            }
        }
    }

    // 6. Cleanup finale
    csv.close();
    delete[] file_buffer;
    cudaFree((void*)d_file_buffer);
    cudaFree((void*)d_occurrences);
    if(longest_prefix_suffix_array) delete[] longest_prefix_suffix_array;
    
    cout << "\nBOOM! Benchmark completato con successo. Risultati salvati in benchmark_results.csv" << endl;
    return 0;
}