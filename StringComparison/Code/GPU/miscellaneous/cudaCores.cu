#include <iostream>
#include <cuda_runtime.h>

int getCoresPerSM(int major, int minor) {
    switch (major) {
        case 2: return (minor == 1) ? 48 : 32;       // Fermi
        case 3: return 192;                          // Kepler
        case 5: return 128;                          // Maxwell
        case 6: return (minor == 0) ? 64 : 128;      // Pascal
        case 7: return 64;                           // Volta / Turing
        case 8: return (minor == 0) ? 64 : 128;      // Ampere / Ada
        case 9: return 128;                          // Hopper
        case 10: return 128;                         // Blackwell (Datacenter)
        case 12: return 128;                         // Blackwell (RTX 50-series)
        default: return -1; 
    }
}

int main() {
    cudaDeviceProp prop;
    cudaError_t err = cudaGetDeviceProperties(&prop, 0);

    if (err != cudaSuccess) {
        std::cerr << "Errore CUDA: " << cudaGetErrorString(err) << "\n";
        return 1;
    }

    int coresPerSM = getCoresPerSM(prop.major, prop.minor);
    
    std::cout << "GPU: " << prop.name << " (Architettura " << prop.major << "." << prop.minor << ")\n";
    std::cout << "Streaming Multiprocessors (SM): " << prop.multiProcessorCount << "\n";
    
    if (coresPerSM != -1) {
        int totalCores = coresPerSM * prop.multiProcessorCount;
        std::cout << "\n====================================\n";
        std::cout << ">>> CUDA CORES TOTALI: " << totalCores << " <<<\n";
        std::cout << "====================================\n";
    } else {
        std::cout << "\nERRORE: Architettura non riconosciuta nello switch.\n";
    }

    return 0;
}