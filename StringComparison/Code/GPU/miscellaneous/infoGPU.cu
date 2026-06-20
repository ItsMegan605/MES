#include <iostream>
#include <cuda_runtime.h>
#include <string>

// Kernel fittizio necessario per calcolare l'occupazione
__global__ void dummyKernel() {
    // Vuoto
}

// Funzione helper per calcolare i CUDA core
int getCoresPerSM(int major, int minor) {
    switch (major) {
        case 3: return 192;
        case 5: return 128;
        case 6: return (minor == 1 || minor == 2) ? 128 : 64;
        case 7: return 64;
        case 8: return (minor == 0) ? 64 : 128;
        case 9: return 128;
        default: return -1;
    }
}

int main() {
    int deviceCount;
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
        
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, dev);

        // Estrazione di alcuni attributi extra tramite API (metodo robusto)
        int clockRateKHz = 0, memoryClockRateKHz = 0, memoryBusWidth = 0, l2CacheSize = 0;
        cudaDeviceGetAttribute(&clockRateKHz, cudaDevAttrClockRate, dev);
        cudaDeviceGetAttribute(&memoryClockRateKHz, cudaDevAttrMemoryClockRate, dev);
        cudaDeviceGetAttribute(&memoryBusWidth, cudaDevAttrGlobalMemoryBusWidth, dev);
        cudaDeviceGetAttribute(&l2CacheSize, cudaDevAttrL2CacheSize, dev);

        std::cout << "\nDispositivo " << dev << ": \"" << prop.name << "\"\n";
        std::cout << "----------------------------------------------------\n";

        // --- Info Sistema e PCI ---
        std::cout << "[Identita' e Sistema PCI]\n";
        std::cout << "  PCI Bus ID / Device ID / Domain ID:            " << prop.pciBusID << " / " << prop.pciDeviceID << " / " << prop.pciDomainID << "\n";
        std::cout << "  TCC Driver (Tesla Compute Cluster):            " << (prop.tccDriver ? "Si" : "No") << "\n";
        std::cout << "  Fa parte di una Multi-GPU Board:               " << (prop.isMultiGpuBoard ? "Si" : "No") << "\n\n";
        
        // --- Architettura e Calcolo ---
        std::cout << "[Architettura e Calcolo]\n";
        std::cout << "  Compute Capability:                            " << prop.major << "." << prop.minor << "\n";
        std::cout << "  Numero di Multiprocessori (SM):                " << prop.multiProcessorCount << "\n";
        
        int coresPerSM = getCoresPerSM(prop.major, prop.minor);
        if(coresPerSM != -1) {
            std::cout << "  CUDA Cores per SM:                             " << coresPerSM << "\n";
            std::cout << "  CUDA Cores Totali:                             " << (coresPerSM * prop.multiProcessorCount) << "\n";
        }
        std::cout << "  Clock Rate dei Core:                           " << clockRateKHz << " kHz (" << clockRateKHz/1000.0f << " MHz)\n\n";

        // --- Gerarchia di Memoria ---
        std::cout << "[Gerarchia di Memoria]\n";
        std::cout << "  Memoria Globale Totale:                        " << prop.totalGlobalMem / (1024*1024) << " MB (" << prop.totalGlobalMem << " bytes)\n";
        std::cout << "  Memoria Costante Totale:                       " << prop.totalConstMem << " bytes\n";
        std::cout << "  Memoria Condivisa (Shared) per Blocco:         " << prop.sharedMemPerBlock << " bytes\n";
        std::cout << "  Memoria Condivisa (Shared) per SM:             " << prop.sharedMemPerMultiprocessor << " bytes\n";
        std::cout << "  Memoria Condivisa (Shared) max Opt-in/Blocco:  " << prop.sharedMemPerBlockOptin << " bytes\n";
        std::cout << "  Dimensione Cache L2:                           " << l2CacheSize << " bytes\n";
        std::cout << "  Clock Rate della Memoria:                      " << memoryClockRateKHz << " kHz\n";
        std::cout << "  Ampiezza Bus di Memoria:                       " << memoryBusWidth << "-bit\n";
        std::cout << "  Supporto ECC (Error Correcting Code):          " << (prop.ECCEnabled ? "Attivo" : "Disabilitato") << "\n";
        std::cout << "  Allineamento Texture / Pitch:                  " << prop.textureAlignment << " bytes / " << prop.texturePitchAlignment << " bytes\n\n";

        // --- Limiti di Esecuzione (Thread, Blocchi, Griglie) ---
        std::cout << "[Limiti di Esecuzione (Fisici)]\n";
        std::cout << "  Warp Size:                                     " << prop.warpSize << " thread\n";
        std::cout << "  Registri (32-bit) disponibili per Blocco:      " << prop.regsPerBlock << "\n";
        std::cout << "  Registri (32-bit) disponibili per SM:          " << prop.regsPerMultiprocessor << "\n";
        std::cout << "  Thread massimi per Multiprocessore (SM):       " << prop.maxThreadsPerMultiProcessor << "\n";
        std::cout << "  Thread massimi per Blocco:                     " << prop.maxThreadsPerBlock << "\n";
        std::cout << "  Dimensione max del Blocco (x, y, z):           (" << prop.maxThreadsDim[0] << ", " << prop.maxThreadsDim[1] << ", " << prop.maxThreadsDim[2] << ")\n";
        std::cout << "  Dimensione max della Griglia (x, y, z):        (" << prop.maxGridSize[0] << ", " << prop.maxGridSize[1] << ", " << prop.maxGridSize[2] << ")\n\n";

        // --- Funzionalità Avanzate ---
        std::cout << "[Funzionalita' Avanzate e Capacita']\n";
        std::cout << "  Esecuzione Kernel Concorrenti:                 " << (prop.concurrentKernels ? "Si" : "No") << "\n";
        std::cout << "  Motori Asincroni (Copy Engines):               " << prop.asyncEngineCount << "\n";
        std::cout << "  Unified Addressing (UVA):                      " << (prop.unifiedAddressing ? "Si" : "No") << "\n";
        std::cout << "  Memoria Gestita (Managed Memory):              " << (prop.managedMemory ? "Si" : "No") << "\n";
        std::cout << "  Accesso Concorrente a Memoria Gestita:         " << (prop.concurrentManagedAccess ? "Si" : "No") << "\n";
        std::cout << "  Host Memory Mapping (Zero-Copy):               " << (prop.canMapHostMemory ? "Si" : "No") << "\n";
        std::cout << "  Cooperative Launch:                            " << (prop.cooperativeLaunch ? "Si" : "No") << "\n";
        std::cout << "  Priorita' degli Stream:                        " << (prop.streamPrioritiesSupported ? "Si" : "No") << "\n";
        std::cout << "  Preemption del Calcolo (Compute Preemption):   " << (prop.computePreemptionSupported ? "Si" : "No") << "\n\n";

        // --- Occupazione Reale Calcolata ---
        std::cout << "[Occupazione Reale Stimata]\n";
        int numBlocksPerSm;
        int numThreads = 256;
        size_t dynamicSharedMemSize = 0; 

        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            dummyKernel, 
            numThreads, 
            dynamicSharedMemSize
        );

        int max_concurrent_blocks_on_gpu = numBlocksPerSm * prop.multiProcessorCount;
        int max_concurrent_threads_on_gpu = max_concurrent_blocks_on_gpu * numThreads;

        std::cout << "  (Test eseguito con kernel vuoto e blocchi da " << numThreads << " thread)\n";
        std::cout << "  Max Blocchi Concorrenti per SM:                " << numBlocksPerSm << "\n";
        std::cout << "  Max Blocchi Concorrenti su tutta la GPU:       " << max_concurrent_blocks_on_gpu << "\n";
        std::cout << "  Max Thread Concorrenti in esecuzione:          " << max_concurrent_threads_on_gpu << "\n";
        
        std::cout << "====================================================\n";
    }

    return 0;
}