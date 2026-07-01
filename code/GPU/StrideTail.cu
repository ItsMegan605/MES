#include "shared.h"

#ifdef BENCHMARK

    #include "bench.cu"

#else

    #include "shared.cu"

#endif

#ifndef VARS

    #define TYPE uint4
    #define EXP 4
    #define ROUND roundToSixteen

#endif
//NB: vars with d are the "copy" of the CPU parameters

void implementationDependantManagement(){

    int target_string_len = strlen(target_string);

    int deviceId;
    cudaGetDevice(&deviceId); 

    cudaDeviceProp props;
    cudaGetDeviceProperties(&props, deviceId);
    
    #ifdef MAX_OCCUPANCY

        // We ask CUDA how many blocks can fit with this shared memory
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            parallelStringSearch, 
            threadsPerBlock, 
            128 
        );  

        
    #endif
    int target_blocks = numBlocksPerSm; // debug
    
    //shared_memory_size = props.sharedMemPerMultiprocessor / numBlocksPerSm;
    shared_memory_size = (numBlocksPerSm > 1) ? (sharedMemLimit*1024) / numBlocksPerSm : 48*1024;
    // FORCES 16-BYTE ALIGNMENT (Truncates to the lower 16 bytes)
    shared_memory_size = shared_memory_size & ~15ULL;


    cout << "Theoretical blocks per SM: " << numBlocksPerSm << endl;
    cout << "Shared Memory per Block: " << shared_memory_size  << " B" << endl;

    // numBlocksPerSm *= 1; // number of waves

    // We query the specific attributes of our kernel
    cudaFuncAttributes attr;
    cudaFuncGetAttributes(&attr, parallelStringSearch);

    cout << "--- KERNEL INFO ---" << endl;
    cout << "Registers used per thread: " << attr.numRegs << endl;
    cout << "Static shared memory per block: " << attr.sharedSizeBytes << " bytes" << endl;
    cout << "-------------------" << endl;
            
    blocksPerGrid = numBlocksPerSm * props.multiProcessorCount;
    
    #ifdef MAX_OCCUPANCY

        // We ask CUDA how many blocks can fit with this shared memory
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &numBlocksPerSm, 
            parallelStringSearch, 
            threadsPerBlock, 
            shared_memory_size
        );  

        cout << "Actual blocks per SM: " << numBlocksPerSm << endl;

    #endif

    cudaMemcpyToSymbol(d_shared_memory_size, &shared_memory_size, sizeof(u64));

    
    int max_smem_per_block_allowed = 0;

    // We start from a very high hypothesis and go down in steps of 256 bytes
    for (int smem_test = 100*1024; smem_test >= 0; smem_test -= 256) {
        int active_blocks;
        
        cudaOccupancyMaxActiveBlocksPerMultiprocessor(
            &active_blocks, 
            parallelStringSearch, 
            threadsPerBlock, 
            smem_test
        );

        // As soon as CUDA confirms that at this size the blocks survive, we stop.
        if (active_blocks >= target_blocks) {
            max_smem_per_block_allowed = smem_test;
            break;
        }
    }

    // Now we calculate the exact overhead
    int total_physical_smem = props.sharedMemPerMultiprocessor; // Your physical ~100KB or 128KB
    int max_usable_smem = max_smem_per_block_allowed * target_blocks;
    int driver_overhead = total_physical_smem - max_usable_smem;

    cout<< "Memory required per SM: "<< sharedMemLimit<< " KB"<<endl;

    cout << "--- HARDWARE OVERHEAD ANALYSIS ---" << endl;
    cout << "Total physical memory of the SM: " << total_physical_smem << " bytes" << endl;
    cout << "Maximum allowed limit per block (to have " << target_blocks << " blocks): " 
        << max_smem_per_block_allowed << " bytes" << endl;
    cout << "Total usable memory for the "<< target_blocks <<" blocks: " << max_usable_smem << " bytes (" << max_usable_smem / 1024 << " KB )" << endl;
    cout << "OVERHEAD (Space stolen by Driver/L1/Metadata): " << driver_overhead << " bytes (" 
        << driver_overhead / 1024.0 << " KB)" << endl;
    cout << "---------------------------------" << endl;

}


__global__ void parallelStringSearch(char* file_buffer, u64* occurrences){
    
    extern __shared__ char shared_buffer[];

    const u32 block_pos = threadIdx.x; // thread id in the block
    
    // Since d_shared_memory_size is a multiple of 16 and d_target_string_len 
    // is rounded to 16, chunk_step will ALWAYS be a multiple of 16.
    // As a result, startPrelievo will always be perfectly aligned!

    // Step calculated to create overlap between blocks and not lose
    // words that fall across the boundary between one chunk and another.
    const u32 overlap = ROUND(d_target_string_len - 1);
    const u64 chunk_step = d_shared_memory_size - overlap;
    const u64 block_jump = chunk_step * gridDim.x;
    
    u32 my_occurrences = 0;

    for(u64 startPrelievo = chunk_step * blockIdx.x; startPrelievo < d_file_size; startPrelievo += block_jump){
        
        // We avoid reading past the end of the file
        u64 limPrelievo = d_shared_memory_size; // I see the bytes yet to be transferred
        bool is_last_block = false;

        if(startPrelievo + limPrelievo > d_file_size) {
            limPrelievo = d_file_size - startPrelievo;
            is_last_block = true;
        }

        u64 limPrelievoLarge = ROUND(limPrelievo) >> EXP;
        u64 startPrelievoLarge = ROUND(startPrelievo) >> EXP;

        // accesses will always be aligned to 4, here I look for TYPE
        for(u64 thisPrelievo = block_pos; thisPrelievo < limPrelievoLarge; thisPrelievo += blockDim.x){
            ((TYPE*)shared_buffer)[thisPrelievo] = ((TYPE*)file_buffer)[(startPrelievoLarge) + thisPrelievo];
        }

        
        __syncthreads();

        if(limPrelievo >= d_target_string_len){
            u64 searchLimit;
            if(is_last_block)
                searchLimit = limPrelievo - d_target_string_len;
            else
                searchLimit = limPrelievo - overlap - 1;
            for(u64 startSearch = block_pos; startSearch <= searchLimit; startSearch += blockDim.x){
                u32 i = 0;
                for(; i < d_target_string_len ; i++){ // string comparison
                    if(shared_buffer[startSearch + i] != d_target_string[i])
                        break; 
                }
                if(i == d_target_string_len)
                    my_occurrences++; // if I find an occurrence
            }
        }     
        __syncthreads();
        
    } 

    
    u64 * shared_occurrences = (u64*)shared_buffer;
    
    if(block_pos == 0) {
        *shared_occurrences = 0;
    }
    
    __syncthreads(); 
    
    if(my_occurrences > 0) {
        atomicAdd(shared_occurrences, my_occurrences);
    }
    
    __syncthreads(); 
    
    if(block_pos == 0 && *shared_occurrences > 0) {
        atomicAdd(occurrences, *shared_occurrences);
    }
    
}