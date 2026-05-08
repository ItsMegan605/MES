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
#include <stdio.h>
#include <cuda_runtime.h>
//#include <windows.h>

#define FILE_PATH "giant_file.txt"

#define MAX_VRAM 8000 // in MByte

using namespace std;
namespace fs = filesystem;

//windows uses 32 bit values for file reading
const std::uintmax_t max_read_size = 2000LL* 1024*1024;

// GPU pointers
__global__ char* d_file_buffer
__global__ unsigned int* d_occurrences
__constant__ char* d_target_string;
__constant__ unsigned int* d_target_sting_len;
__constant__ unsigned long long * d_file_size;
__shared__ char* d_local_buffer;


#endif