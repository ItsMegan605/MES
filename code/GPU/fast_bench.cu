#include "shared.h"
#include <vector>
#include <string>
#include <fstream>
#include <iomanip>
#include <locale>
#include <utility> // Aggiunto per std::pair

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

    
    char * output_file = new char[strlen("csv/")+ strlen(argv[1]) + strlen(".csv") + 1]; // + .csv + \0
    strcpy(output_file,"csv/");
    strcpy(output_file + strlen("csv/") ,argv[1]);
    strcpy(output_file + strlen("csv/") + strlen(argv[1]), ".csv");

    // 1. Setup Configurazioni del Benchmark
    std::vector<std::string> strings = {"unevenstring"};
    std::vector<u64> file_sizes_mb = {3000,4000, 5000, 6000, 7000,8000};
    
    // Vettore per le configurazioni <thread, shared>
    std::vector<std::pair<u64, u32>> configs = {
        {32, 72}, {64, 72}, {96, 84}, {128, 87}, {160, 90}, 
        {192, 92}, {224, 93}, {256, 93}, {288, 95}
    };
    std::vector<int> nblocks = {1}; // Valori di esempio

    
    const int runs = 30;

    // 2. Setup del file CSV
    std::ofstream csv(output_file);
    if (!csv) {
        cerr << "Errore: impossibile creare <<"<< output_file<<endl;
        return 1;
    }
    // Applica la formattazione italiana (virgola per i decimali)
    csv.imbue(std::locale(csv.getloc(), new comma_facet()));
    
    // Rimossa la colonna "limite shared mem"
    csv << "stringa cercata;thread per blocco;blocchi per SM;ripetizione;dimensione file;throughput\n";

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

            // Itera sulle configurazioni accoppiate invece di fare il prodotto cartesiano
            for(const auto& config : configs) {
                threadsPerBlock = config.first;
                sharedMemLimit = config.second;

                for(int b : nblocks) {
                    numBlocksPerSm = b;
            
                    // Calcola gridDim e shared_memory in base ai nuovi parametri
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

                        // Salvataggio nel file CSV (omettendo la shared memory)
                        csv << str << ";" 
                            << threadsPerBlock << ";" 
                            << numBlocksPerSm << ";" 
                            << r << ";" 
                            << fs_mb << ";" 
                            << std::fixed << std::setprecision(2) << throughput << "\n";
                        
                        // Stampa a schermo
                        cout << "Completata Run " << r << "/" << runs 
                            << " | Str: " << str
                            << " | SM Limit: " << sharedMemLimit
                            << " | Thr: " << threadsPerBlock 
                            << " | Blocchi: " << numBlocksPerSm 
                            << " | Size: " << fs_mb 
                            << "MB | Throughput: " << throughput << endl;
                    }
                }
            }
        }
    }

    // 6. Cleanup finale
    csv.close();
    delete[] output_file; 
    delete[] file_buffer;
    cudaFree((void*)d_file_buffer);
    cudaFree((void*)d_occurrences);
    if(longest_prefix_suffix_array) delete[] longest_prefix_suffix_array;
    
    cout << "\nBenchmark completato con successo. Risultati salvati in " << argv[1] << ".csv" << endl;
    return 0;
}