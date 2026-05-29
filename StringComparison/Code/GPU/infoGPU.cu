#include <iostream>
#include <cuda_runtime.h>

// Kernel fittizio necessario per calcolare l'occupazione
__global__ void dummyKernel() {
    // Vuoto
}

int main() {
    int deviceCount;
    // Controlla se ci sono dispositivi CUDA
    cudaError_t error_id = cudaGetDeviceCount(&deviceCount);

    if (error_id != cudaSuccess) {
        std::cerr << "Errore CUDA: " << cudaGetErrorString(error_id) << std::endl;
        return 1;
    }

    if (deviceCount == 0) {
        std::cout << "Nessuna GPU CUDA compatibile trovata." << std::endl;
        return 1;
    }

    std::cout << "Trovate " << deviceCount << " GPU CUDA compatibili." << std::endl;
    std::cout << "====================================================\n";

    for (int dev = 0; dev < deviceCount; ++dev) {
        cudaSetDevice(dev);
        
        // Estrazione delle info classiche
        cudaDeviceProp deviceProp;
        cudaGetDeviceProperties(&deviceProp, dev);

        // Estrazione delle info per i Clock (Nuovo metodo CUDA 13+)
        int clockRateKHz = 0;
        cudaDeviceGetAttribute(&clockRateKHz, cudaDevAttrClockRate, dev);
        
        int memoryClockRateKHz = 0;
        cudaDeviceGetAttribute(&memoryClockRateKHz, cudaDevAttrMemoryClockRate, dev);

        // Estrazione ampiezza bus di memoria e cache (per sicurezza con i nuovi compilatori)
        int memoryBusWidth = 0;
        cudaDeviceGetAttribute(&memoryBusWidth, cudaDevAttrGlobalMemoryBusWidth, dev);
        
        int l2CacheSize = 0;
        cudaDeviceGetAttribute(&l2CacheSize, cudaDevAttrL2CacheSize, dev);

        std::cout << "\nDispositivo " << dev << ": \"" << deviceProp.name << "\"\n";
        std::cout << "----------------------------------------------------\n";
        
        // --- Architettura e Calcolo ---
        std::cout << "[Architettura e Calcolo]\n";
        std::cout << "  Compute Capability:                            " << deviceProp.major << "." << deviceProp.minor << "\n";
        std::cout << "  Numero di Multiprocessori (SM):                " << deviceProp.multiProcessorCount << "\n";
        std::cout << "  Clock Rate dei Core:                           " << clockRateKHz / 1000 << " MHz\n\n";

        // --- Gerarchia di Memoria ---
        std::cout << "[Gerarchia di Memoria]\n";
        std::cout << "  Memoria Globale Totale:                        " << deviceProp.totalGlobalMem / (1024 * 1024) << " MB\n";
        std::cout << "  Memoria Costante Totale:                       " << deviceProp.totalConstMem / 1024 << " KB\n";
        std::cout << "  Memoria Condivisa (Shared) per Blocco:         " << deviceProp.sharedMemPerBlock / 1024 << " KB\n";
        std::cout << "  Dimensione Cache L2:                           " << l2CacheSize / (1024 * 1024) << " MB\n";
        std::cout << "  Clock Rate della Memoria:                      " << memoryClockRateKHz / 1000 << " MHz\n";
        std::cout << "  Ampiezza Bus di Memoria:                       " << memoryBusWidth << "-bit\n\n";

        // --- Limiti di Esecuzione (Thread, Blocchi, Griglie) ---
        std::cout << "[Limiti di Esecuzione (Fisici)]\n";
        std::cout << "  Warp Size:                                     " << deviceProp.warpSize << " thread\n";
        std::cout << "  Registri a 32-bit disponibili per Blocco:      " << deviceProp.regsPerBlock << "\n";
        std::cout << "  Thread massimi per Multiprocessore (SM):       " << deviceProp.maxThreadsPerMultiProcessor << "\n";
        std::cout << "  Thread massimi per Blocco:                     " << deviceProp.maxThreadsPerBlock << "\n";
        std::cout << "  Dimensione max del Blocco (x, y, z):           (" 
                  << deviceProp.maxThreadsDim[0] << ", " 
                  << deviceProp.maxThreadsDim[1] << ", " 
                  << deviceProp.maxThreadsDim[2] << ")\n";
        std::cout << "  Dimensione max della Griglia (x, y, z):        (" 
                  << deviceProp.maxGridSize[0] << ", " 
                  << deviceProp.maxGridSize[1] << ", " 
                  << deviceProp.maxGridSize[2] << ")\n\n";

        // --- Occupazione Reale Calcolata ---
        std::cout << "[Occupazione Reale Stimata]\n";
        int numBlocksPerSm;
        int numThreads = 256; // Dimensione standard del blocco per il test
        size_t dynamicSharedMemSize = 0; 

        // Calcola i blocchi attivi massimi per questo kernel specifico
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            dummyKernel, 
            numThreads, 
            dynamicSharedMemSize
        );

        int max_concurrent_blocks_on_gpu = numBlocksPerSm * deviceProp.multiProcessorCount;

        std::cout << "  (Test eseguito con kernel vuoto e blocchi da " << numThreads << " thread)\n";
        std::cout << "  Max Blocchi Concorrenti per SM:                " << numBlocksPerSm << "\n";
        std::cout << "  Max Blocchi Concorrenti su tutta la GPU:       " << max_concurrent_blocks_on_gpu << "\n";
        
        std::cout << "====================================================\n";
    }

    return 0;
}