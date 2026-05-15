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

#define MAX_VRAM (unsigned long long)8000*1024*1024 // in MByte, max VRAM 8GB
#define MAX_TARGET_STR 256

#define WARP_SIZE 32 //warp standard dim 

using namespace std;
namespace fs = std::filesystem;

//for command line arg
enum {
    EXE_NAME,
    TARGET_STRING,
    THREADS_PER_BLOCK,
    FILE_LIMIT
};


//windows uses 32 bit values for file reading
const std::uintmax_t max_read_size = 2000LL* 1024*1024;

// temporary ram buffer for the target file
char* file_buffer;

//file dim and string we are looking for
std::uintmax_t file_size;
char* target_string;

// kmp
int* longest_prefix_suffix_array = nullptr;

// ==================== GPU ===========================

//shared memory
size_t shared_memory_size;

// Global memory GPU pointers
char* d_file_buffer;
unsigned long long* d_occurrences;

// read-only GPU pointers in constant memory 
__constant__ unsigned long long d_file_size;

__constant__ char d_target_string[MAX_TARGET_STR];
__constant__ unsigned int d_target_string_len;

__constant__ unsigned long long  d_totalThreads; // naive

__constant__ int d_longest_prefix_suffix_array[MAX_TARGET_STR]; //KMP

// thread management
unsigned long long threadsPerBlock;
unsigned long long blocksPerGrid;
unsigned long long totalThreads; // naive

#endif