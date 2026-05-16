#include "shared.h"
#include "shared.cu"

//NB: le var con d sono la "copia" dei parametri CPU

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);

    
    int numBlocksPerSm = 4;

    /*
    cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &numBlocksPerSm, 
        parallelStringSearch, 
        threadsPerBlock, 
        shared_memory_size
        );  
        */
    cout << "Blocchi per SM: " << numBlocksPerSm << endl;
    cout << "Memoria Condivisa per Blocco: " << ( props.sharedMemPerMultiprocessor / 1024 ) / numBlocksPerSm<< " KB" << endl;
            
    // Calcoliamo la griglia totale moltiplicando i blocchi per SM per il numero di SM
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;

    // totalThreads a questo punto è semplice:
    totalThreads = blocksPerGrid * threadsPerBlock;

    shared_memory_size = props.sharedMemPerMultiprocessor / numBlocksPerSm;


    cudaMemcpyToSymbol(d_totalThreads, &totalThreads, sizeof(unsigned long long));
    cudaMemcpyToSymbol(d_shared_memory_size, &shared_memory_size, sizeof(unsigned int));

    /*
    cout << "--- IDENTIKIT HARDWARE DELLA GPU ---" << endl;
    cout << "Memoria Condivisa Totale per SM: " << props.sharedMemPerMultiprocessor / 1024 << " KB" << endl;
    cout << "Blocchi per SM: " << numBlocksPerSm << endl;
    cout << "Memoria Condivisa per Blocco: " << ( props.sharedMemPerMultiprocessor / 1024 ) / numBlocksPerSm<< " KB" << endl;
    
    cout << "Memoria Condivisa MAX per singolo Blocco: " << props.sharedMemPerBlock / 1024 << " KB" << endl;
    cout << "Registri Totali per SM: " << props.regsPerMultiprocessor << endl;
    cout << "Registri MAX per singolo Blocco: " << props.regsPerBlock << endl;
    cout << "Numero di SM (Processori): " << props.multiProcessorCount << endl;
    cout << "------------------------------------" << endl;
    */
    
}


__global__ void parallelStringSearch(char* file_buffer, unsigned long long* occurrences){

    unsigned long long block_start = (unsigned long long)blockDim.x * blockIdx.x; //indice di inziio lavoro 
    unsigned long long global_id = threadIdx.x + block_start; //id dei thread
    
    extern __shared__ char shared_buffer[];

    const unsigned int block_pos = threadIdx.x; //id del thread nel blocco
    const unsigned int block_size = blockDim.x;
    //total thread in exe, tutti i thread esistenti per vedere che alti fanno
    const unsigned long long stride = (unsigned long long)blockDim.x * gridDim.x;
    const unsigned long long block_jump = d_shared_memory_size * gridDim.x;
    
    unsigned long long my_occurrences = 0;
    //max lim di ricerca 
    unsigned long long last_int = roundToFour(d_file_size - d_target_string_len + 1);

    for(unsigned long long startPrelievo = d_shared_memory_size * blockIdx.x; startPrelievo < d_file_size; startPrelievo += block_jump){
        
        // fare che il prelievo sia a multipli di shared memory risparmiandoci un if
        unsigned long long limPrelievo = ((d_shared_memory_size < d_file_size - startPrelievo ) ? shared_memory_size : d_file_size - startPrelievo);
        for(unsigned long long thisPrelievo = block_pos * 4; thisPrelievo + 3 < limPrelievo; thisPrelievo += block_size * 4){
            *((int*)(&shared_buffer[thisPrelievo])) = *((int*)(&file_buffer[startPrelievo + thisPrelievo]));
        }

        __syncthreads();

        /// work in progress

        __syncthreads();
    }

    //usare shared buffer per salvare le occorrenze shared
    /*
    if(my_occurrences > 0)
    atomicAdd(&shared_occurrences,my_occurrences);
    
    __syncthreads();
    
    if(block_pos == 0 && shared_occurrences > 0)
    atomicAdd(occurrences,shared_occurrences);
    
    */
}

int main(int argc, char* argv[]);