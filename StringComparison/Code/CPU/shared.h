#ifndef SHARED_H
#define SHARED_H

// This file contains all global variables and constants, both for normal and optimized version of the application

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

#define FILE_PATH "giant_file.txt"
#define MIN_INPUTS 3

using namespace std;
namespace fs = filesystem;

typedef unsigned int u32;
typedef unsigned long long u64;

enum {
    EXE_NAME,
    TARGET_STRING,
    NUM_THREADS,
    FILE_LIMIT
};

char* file_buffer;
char* end_of_file;

char* target_string;

int* longest_prefix_suffix_array;

int occurrences = 0;
atomic_int atomic_occurrences(0);

int num_threads;

mutex mtx;
mutex output_mtx;

//windows uses 32 bit values for file reading
const u64 max_read_size = 2000LL* 1024*1024;

u64 file_size;

// static load
u64 chunk_size;

// dynamic load
mutex chunk_mtx;
const u64 CHUNK_SIZE = 5*1024*1024;
u64 next_chunk_size = 0; 

#endif