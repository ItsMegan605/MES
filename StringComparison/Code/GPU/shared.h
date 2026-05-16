#ifndef SHARED_H
#define SHARED_H

#define DEBUG 

#include <iostream>
#include <string>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <vector>
#include <thread>
#include <atomic>
#include <chrono>
#include <mutex>
#include <stdio.h>
#include <cuda_runtime.h>

//genertal constants
#define FILE_PATH "../CPU/giant_file.txt"
#define MIN_INPUTS 3 //arg command line

#define MAX_VRAM (u64)8000*1024*1024 // in MByte, max VRAM 8GB
#define MAX_TARGET_STR 256

#define WARP_SIZE 32 //warp standard dim 

using namespace std;
namespace fs = std::filesystem;

typedef unsigned int u32;
typedef unsigned long long u64;

//for command line arg
enum {
    EXE_NAME,
    TARGET_STRING,
    THREADS_PER_BLOCK,
    FILE_LIMIT
};


//windows uses 32 bit values for file reading
const u64 max_read_size = 2000LL* 1024*1024;

// temporary ram buffer for the target file
char* file_buffer;

//file dim and string we are looking for
u64 file_size;
char* target_string;

// kmp
int* longest_prefix_suffix_array = nullptr;

// ==================== GPU ===========================

//shared memory
u64 shared_memory_size;

// Global memory GPU pointers
char* d_file_buffer;
u64* d_occurrences;

// read-only GPU pointers in constant memory 
__constant__ u64 d_file_size;

__constant__ char d_target_string[MAX_TARGET_STR];
__constant__ u32 d_target_string_len;

__constant__ u32 d_shared_memory_size;

__constant__ u64  d_totalThreads; // naive

__constant__ int d_longest_prefix_suffix_array[MAX_TARGET_STR]; //KMP

// thread management
u64 threadsPerBlock;
u64 blocksPerGrid;
u64 totalThreads; // naive

#endif