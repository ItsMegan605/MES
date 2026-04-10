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
#include <windows.h>

#define FILE_PATH "gigante_uneven.txt"

//global variables
using namespace std;
namespace fs = filesystem;

char* file_buffer;

char* target_string;

int* longest_prefix_suffix_array;

atomic_int occurrences(0);

int num_threads;

//windows uses 32 bit values for file reading
const std::uintmax_t max_read_size = 2000LL* 1024*1024;

std::uintmax_t file_size;

// chunk info
const std::uintmax_t CHUNK_SIZE = 15*1024*1024;
mutex chunk_mtx;
std::uintmax_t next_chunk_size = 0; 

//mutex output_mtx; 

void build_table(int len){
    char * head, *tail;
    head = tail = target_string;
    int pos = 0;
    longest_prefix_suffix_array[0]=0;
    tail++;
    for(int i = 1; i < len; i++){
        if(*tail == *head){
            pos++;
            longest_prefix_suffix_array[i] = pos;
            head++;
        }else{
            pos = 0;
            longest_prefix_suffix_array[i]=0;
            head = target_string;
        }
        tail++;
    }
}


uintmax_t getNewChunk(){
    lock_guard<mutex> lk(chunk_mtx);
    uintmax_t current_start = next_chunk_size;
    next_chunk_size += CHUNK_SIZE
;
    return current_start;
}

void findStringIstance(int thread_index){

    uintmax_t current_chunk_start = getNewChunk();
    long long bytes_left = (file_size - current_chunk_start < CHUNK_SIZE) ? file_size - current_chunk_start : CHUNK_SIZE;

    int target_string_length = strlen(target_string);

    unsigned long target_index = 0, candidate_index = current_chunk_start;
    int local_occurrences = 0;

    int extra_search_field = (file_size - current_chunk_start < CHUNK_SIZE) ? 0 : target_string_length - 1;
    
    //chrono::steady_clock::time_point start = chrono::steady_clock::now();

    while(current_chunk_start < file_size){
        while(true){
            if(bytes_left <= 0){
                if(target_index != 0){
                    extra_search_field--;
                    if(extra_search_field < 0)
                        break;
                }else
                    break;
            }
            if(target_string[target_index] == file_buffer[candidate_index]){
                target_index++;
                candidate_index++;
                bytes_left--;

                if(target_index == target_string_length){
                    local_occurrences++;
                    target_index = longest_prefix_suffix_array[target_index - 1];
                }
            }else{
                if(target_index != 0)
                    target_index = longest_prefix_suffix_array[target_index - 1];
                else{
                    candidate_index++;
                    bytes_left--;
                }
            }
        }
        if(extra_search_field < 0)
            break;
        current_chunk_start = getNewChunk();
        target_index = 0;
        candidate_index = current_chunk_start;

        if(file_size - current_chunk_start < CHUNK_SIZE){
            bytes_left = file_size - current_chunk_start;
            extra_search_field = 0;
        } else {
            bytes_left = CHUNK_SIZE;
            extra_search_field = target_string_length - 1;
        }

    }
    occurrences+=local_occurrences;
    //chrono::steady_clock::time_point end = chrono::steady_clock::now();
    //chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);

    /* for debug
    output_mtx.lock();
    cout << "Thread " << thread_index << " finished in: " << duration.count() << endl;
    output_mtx.unlock();
    output_mtx.lock();
    cout << "Thread " << thread_index << " finished. Occurrences so far: " << local_occurrences << endl;
    output_mtx.unlock();
    */
}

void parallelStringSearch(int num_threads) {

    vector<thread> threads;

    for(int i = 0; i < num_threads-1; i++){
        threads.emplace_back(findStringIstance, i);
    }
    findStringIstance(num_threads-1); // il main thread e' l'ultimo

    for(auto& t : threads){
        t.join(); //attendiamo fine threads
    }
    //cout << "Occurrences of \"" << target_string << "\": " << occurrences.load() << endl;
}



//intanto mettiamo le cose nell main poi fare funzini esterne

int main(int argc, char* argv[]) {

    if (argc < 3) {
        cout << "Insert the target string and the number of threads as arguments." << endl;
        return 1;
    }

    target_string = argv[1]; //prende la prima parola passata come argomento
    num_threads = stoi(argv[2]); //prende il numero di thread da terminale    

    try {
        file_size = fs::file_size(FILE_PATH);

    } catch (const fs::filesystem_error& e) {
        
        cerr << "Impossibile leggere il file: " << e.what() << '\n';
        return 1;
    }

    file_size = 2*1000*1024*1024; //DA LEVARE
    
    //operazioni per fare il compare
    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Errore: impossibile aprire il file per la lettura.\n";
        return 1;
    }
    file_buffer = new char[file_size];

    //Legge il file un blocco alla volta finchÃ¨ non finisce
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

    int target_string_len = strlen(target_string); 
    longest_prefix_suffix_array = new int[strlen(target_string)];
    build_table(target_string_len);

    chrono::steady_clock::time_point start = chrono::steady_clock::now();
    parallelStringSearch(num_threads);
    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);
    //cout<< duration.count() <<endl;
    cout << ((double)file_size / duration.count())* 1000 << endl;


    //chiusura del file 
    delete[] longest_prefix_suffix_array;
    delete[] file_buffer;
    return 0;
    
}