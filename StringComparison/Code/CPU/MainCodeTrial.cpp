#include <iostream>
#include <string>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <vector>
#include <thread>
#include <chrono>
#include <mutex>
#include <ittnotify.h>

#define FILE_PATH "gigante.txt"

//global variables
using namespace std;
namespace fs = filesystem;
//pointers to save the text and the string to compare
char* file_buffer;
char* end_of_file;

char* target_string;

int occurrences = 0;
int num_threads;
mutex mtx;
//mutex output_mtx; 

const std::uintmax_t max_read_size = 2000LL* 1024*1024;

std::uintmax_t file_size;
std::uintmax_t chunk_size;

//function to chech if the chars match the target word
//returns the number of chars that match, if it is equal to the length of the target string then we have found an occurrence
unsigned long checkString(char* candidate_match, char* target){
    unsigned long j;
    for(j = 0; j < strlen(target_string); j++){
        if(candidate_match[j] != target[j] || (candidate_match + strlen(target_string) >= end_of_file)){
            break;
        }
    }
    return j;
}

//functon executed by every thread, analyzes a chunk of the file and counts the occurrences 
void findStringIstance(int thread_index, int remainder){

    unsigned long file_position = thread_index * chunk_size;
    int temp = 0;

    for(unsigned long i = 0; i < chunk_size + remainder; i++){
        
        if(checkString(&file_buffer[file_position], target_string) == strlen(target_string)){
            mtx.lock();
            occurrences++;
            mtx.unlock();
            temp++;
        }
        file_position++;
        

    }
    /*
    output_mtx.lock();
    cout << "Thread " << thread_index << " finished. Occurrences so far: " << temp << endl;
    output_mtx.unlock();
    */
}

//creation and thread waiting
void parallelStringSearch(int num_threads) {

    vector<thread> threads;

    __itt_resume();

    for(int i = 0; i < num_threads-1; i++){
        threads.emplace_back(findStringIstance, i, 0);
    }
    findStringIstance(num_threads-1, file_size%num_threads); //main thread is the last one
    for(auto& t : threads){
        t.join(); //wait for threads to finish
    }
   //cout << "Occurrences of \"" << target_string << "\": " << occurrences<< endl;
   __itt_pause();

}

int main(int argc, char* argv[]) {
    __itt_pause();
    
    if (argc < 3) {
        cout << "Insert the target string and the number of threads as arguments." << endl;
        return 1;
    }
    
    target_string = argv[1]; //word to compare, taken from terminal
    num_threads = stoi(argv[2]); //number of threads, taken from terminal
    
    try {
        file_size = fs::file_size(FILE_PATH);

    } catch (const fs::filesystem_error& e) {
        
        cerr << "Impossibile leggere il file: " << e.what() << '\n';
        return 1;
    }
    
    chunk_size = file_size / num_threads; //dimension of the chunck for each threas
    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Errore: impossibile aprire il file per la lettura.\n";
        return 1;
    }
    file_buffer = new char[file_size];
    end_of_file = file_buffer + file_size + 1;
    
    // 3. Legge il file un blocco alla volta finché non finisce
    std::uintmax_t bytes_left = file_size;
    char* buffer_offset = file_buffer;
    while(bytes_left){
        std::uintmax_t bytes_to_read = (bytes_left > max_read_size) ? max_read_size : bytes_left;

        file.read(buffer_offset, bytes_to_read);
        if(file.gcount() <= 0 || file.gcount() != bytes_to_read) {
            cout <<"Error in file.read()"<< endl;
            delete[] file_buffer;
            return 0;
        }
        buffer_offset += bytes_to_read;
        bytes_left -= bytes_to_read;
    }

    //timing the search
    chrono::steady_clock::time_point start = chrono::steady_clock::now();
    parallelStringSearch(num_threads);
    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);
    //cout << duration.count() <<';';

    cout << ((double)file_size / duration.count())* 1000 << endl;


    //close the file 
    delete[] file_buffer;
    return 0;
    
}