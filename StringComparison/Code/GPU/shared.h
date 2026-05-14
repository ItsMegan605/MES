#ifndef SHARED_H
#define SHARED_H

#define DEBUG // uncomment for debug output

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

// This file contains all global variables and constants, both for normal and optimized version of the application
#define FILE_PATH "../CPU/giant_file.txt"
#define MIN_INPUTS 3

#define MAX_VRAM (unsigned long long)8000*1024*1024 // in MByte
#define MAX_TARGET_STR 256

#define WARP_SIZE 32

using namespace std;
namespace fs = std::filesystem;

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

std::uintmax_t file_size;
char* target_string;

// kmp
int* longest_prefix_suffix_array = nullptr;

// ==================== GPU ===========================

// memory parameters
size_t shared_memory_size;

// Global memory GPU pointers
char* d_file_buffer;
unsigned long long* d_occurrences;

// read-only GPU pointers
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