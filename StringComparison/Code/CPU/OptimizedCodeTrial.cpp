#include <iostream>
#include <string>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <vector>
#include <thread>
#include <atomic>

#define FILE_PATH "gigante.txt"

//global variables
using namespace std;
namespace fs = filesystem;

char* file_buffer;
char* target_string;

atomic_int occurrences(0);

int num_threads;

std::uintmax_t file_size;
std::uintmax_t chunk_size;

unsigned long checkString(char*head,char*iterator,unsigned long file_position){
    unsigned long j;
    for(j = 0; j < strlen(target_string); j++){
        if(iterator[j] != head[j] || (file_position + strlen(target_string) >= file_size)){
            break;
        }
    }
    return j;
}


void findStringIstance(int thread_index, int remainder){
    char* file_chunk_start = file_buffer + thread_index * chunk_size;

    char * head = file_chunk_start;
    char * iterator = target_string;
    unsigned long chunk_offset = thread_index * chunk_size;

    for(unsigned long i = 0; i < chunk_size + remainder; i++){
        
        if(checkString(&head[i],iterator,chunk_offset + i) == strlen(target_string))
            occurrences++;
    }
}

void parallelStringSearch(int num_threads) {

    vector<thread> threads;

    for(int i = 0; i < num_threads-1; i++){
        threads.emplace_back(findStringIstance, i, 0);
    }
    findStringIstance(num_threads-1, file_size%num_threads); // il main thread e' l'ultimo

    for(auto& t : threads){
        t.join(); //attendiamo fine threads
    }
    cout << "Occurrences of \"" << target_string << "\": " << occurrences.load() << endl;

}



//intanto mettiamo le cose nell main poi fare funzini esterne

int main(int argc, char* argv[]) {
    if (argc < 4) {
        cout << "Insert at least one word as an argument." << endl;
        //return 1;
    }
    
    target_string = "albero";//argv[1]; //prende la prima parola passata come argomento
    num_threads = 5;//stoi(argv[2]); //prende il numero di thread da terminale
    char* mode = "a"; //argv[3]; //prende il percorso del file da terminale
    

    try {
        file_size = fs::file_size(FILE_PATH);

    } catch (const fs::filesystem_error& e) {
        
        cerr << "Impossibile leggere il file: " << e.what() << '\n';
        return 1;
    }
    
    chunk_size = file_size / num_threads; //calcolo la dimensione del chunk da assegnare a ogni thread
    //operazioni per fare il compare
    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Errore: impossibile aprire il file per la lettura.\n";
        return 1;
    }
    file_buffer = new char[file_size];
    
    // 3. Legge il file un blocco alla volta finché non finisce
    file.read(file_buffer, file_size);
    if(file.gcount() <= 0) {
        cout <<"Error in file.read()"<<endl;
        delete[] file_buffer;
        return 0;
    }
    
    parallelStringSearch(num_threads);

    //chiusura del file 
    delete[] file_buffer;
    return 0;
    
}