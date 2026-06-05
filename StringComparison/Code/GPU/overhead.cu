#include <iostream>
#include <fstream>
#include <vector>
#include <cuda_runtime.h>

typedef unsigned long long u64;

// --- IMPORTANTE ---
// Sostituisci "dummyParallelStringSearch" con il tuo "parallelStringSearch" originale.
// Ho inserito questa funzione fittizia solo per permettere la compilazione standalone.
__global__ void dummyParallelStringSearch(char* file_buffer, u64* occurrences) {
    if (file_buffer == nullptr) return;
    occurrences[0] = 0;
}

int main() {
    int deviceId;
    cudaError_t err = cudaGetDevice(&deviceId);
    if (err != cudaSuccess) {
        std::cerr << "Errore CUDA nel recupero del device: " << cudaGetErrorString(err) << std::endl;
        return 1;
    }

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);

    // SBLOCCO MEMORIA CONDIVISA: Nelle GPU moderne (RTX Serie 30/40/50), per allocare 
    // dinamicamente più di 48KB per blocco è necessario abilitare l'opt-in.
    // SOSTITUISCI dummyParallelStringSearch CON IL TUO KERNEL QUI SOTTO:
    cudaFuncSetAttribute(dummyParallelStringSearch, cudaFuncAttributeMaxDynamicSharedMemorySize, props.sharedMemPerBlockOptin);

    // Memoria base e limiti
    int total_physical_smem = props.sharedMemPerMultiprocessor;
    int base_100KB = 100 * 1024; // I 100 KB base che hai richiesto
    
    // Lista di configurazioni di thread per blocco da testare
    std::vector<int> threads_array = {32, 64, 128, 192, 256, 384, 512, 768, 1024};

    std::cout << "--- ANALISI OVERHEAD HARDWARE ---" << std::endl;
    std::cout << "Dispositivo: " << props.name << std::endl;
    std::cout << "Memoria fisica SM totale: " << total_physical_smem << " bytes" << std::endl;
    std::cout << "Max Shared Memory / Blocco supportata: " << props.sharedMemPerBlockOptin << " bytes" << std::endl;
    std::cout << "---------------------------------\n" << std::endl;

    std::ofstream file_overhead("overhead.csv");
    std::ofstream file_memoria("memoria.csv");

    if (!file_overhead.is_open() || !file_memoria.is_open()) {
        std::cerr << "Errore nell'apertura dei file CSV!" << std::endl;
        return 1;
    }

    // Header per i CSV (Ho aggiunto i Thread così sai a quale configurazione si riferiscono i blocchi)
    file_overhead << "Threads,Numero_Blocchi,Max_Smem_Per_Blocco_Bytes,Overhead_Bytes,Overhead_KB\n";
    file_memoria << "Threads,Numero_Blocchi,Memoria_Disponibile_Bytes,Memoria_Disponibile_KB\n";

    for (int threads : threads_array) {
        int target_blocks = 0;
        
        // 1. CALCOLO MAX BLOCCHI DINAMICO IN BASE AI THREAD
        // Passiamo 0 alla shared memory per isolare il limite dettato solo dai thread/registri.
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &target_blocks, 
            dummyParallelStringSearch, // <-- SOSTITUISCI CON IL TUO KERNEL
            threads, 
            0 
        );

        // Se CUDA non può lanciare questi thread a causa dei registri, saltiamo.
        if (target_blocks == 0) {
            std::cout << "Threads: " << threads << " -> Impossibile lanciare (limite registri o thread eccessivi)" << std::endl;
            continue;
        }

        int max_smem_per_block_allowed = 0;

        // 2. RICERCA DELLA MASSIMA MEMORIA ALLOCABILE
        // Iniziamo dal massimo assoluto consentito per blocco dalla GPU
        int smem_start = total_physical_smem;
        if (smem_start > props.sharedMemPerBlockOptin) {
            smem_start = props.sharedMemPerBlockOptin;
        }

        for (int smem_test = smem_start; smem_test >= 0; smem_test -= 256) {
            int active_blocks = 0;
            
            cudaOccupancyMaxActiveBlocksPerMultiprocessor(
                &active_blocks, 
                dummyParallelStringSearch, // <-- SOSTITUISCI CON IL TUO KERNEL
                threads, 
                smem_test
            );

            // Appena troviamo la memoria che ci consente di mantenere intatti i blocchi teorici
            if (active_blocks >= target_blocks) {
                max_smem_per_block_allowed = smem_test;
                break;
            }
        }

        // 3. CALCOLO OVERHEAD
        int max_usable_smem = max_smem_per_block_allowed * target_blocks;
        int driver_overhead = total_physical_smem - max_usable_smem;
        if (driver_overhead < 0) driver_overhead = 0;

        // 4. CALCOLO MEMORIA DISPONIBILE (100KB - overhead)
        int available_memory = base_100KB - driver_overhead;
        if (available_memory < 0) available_memory = 0;

        // Scrittura CSV
        file_overhead << threads << "," 
                      << target_blocks << "," 
                      << max_smem_per_block_allowed << ","
                      << driver_overhead << "," 
                      << (driver_overhead / 1024.0) << "\n";

        file_memoria << threads << "," 
                     << target_blocks << "," 
                     << available_memory << "," 
                     << (available_memory / 1024.0) << "\n";

        // Stampa a schermo
        std::cout << "Threads: " << threads 
                  << " | Blocchi: " << target_blocks 
                  << " | Smem Max/Blocco: " << (max_smem_per_block_allowed / 1024.0) << " KB"
                  << "\n   -> Overhead: " << (driver_overhead / 1024.0) << " KB"
                  << " | Mem. Disponibile (100KB - Overhead): " << (available_memory / 1024.0) << " KB\n" 
                  << std::endl;
    }

    file_overhead.close();
    file_memoria.close();

    std::cout << "Analisi completata con successo!" << std::endl;
    std::cout << "I risultati sono stati salvati in 'overhead.csv' e 'memoria.csv'." << std::endl;

    return 0;
}