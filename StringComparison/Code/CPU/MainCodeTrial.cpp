#include <iostream>
#include <string>
#include <cstring>
#include <filesystem>
#include <fstream>

#define FILE_PATH "reviews.csv"

using namespace std;
namespace fs = filesystem;

void findStringInstance(int thread_id,char* target_string, char* file, long file_size){
    cout <<"File size: "<<file_size<<endl;
    char * head = file;
    char * iterator = target_string;
    char * tail = file;
    long occurrence = 0;
    // garbage version
    for(unsigned long i = 0; i < file_size; i++){
        unsigned long j;
        for(j = 0; j < strlen(target_string); j++){
            if(iterator[j] != tail[j+i]){
                break;
            }
        }
        if(j == strlen(target_string))
            occurrence++;
    }
    cout << "Occorrenze: "<<occurrence<<endl;

}

//intanto mettiamo le cose nell main poi fare funzini esterne

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cout << "Insert at least one word as an argument." << endl;
        return 1;
    }

    //prendere la stringa da terminale 
    char* inputString = argv[1]; //prende la prima parola passata come argomento



    std::uintmax_t file_size;

    try {
        file_size = fs::file_size(FILE_PATH);

    } catch (const fs::filesystem_error& e) {
        
        cerr << "Impossibile leggere il file: " << e.what() << '\n';
    }
    
    //operazioni per fare il compare
    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Errore: impossibile aprire il file per la lettura.\n";
        return 1;
    }
    char* file_buffer = new char[file_size];
    
    // 3. Legge il file un blocco alla volta finché non finisce
    file.read(file_buffer, file_size);
    if(file.gcount() <= 0) {
        cout <<"Error in file.read()"<<endl;
        delete[] file_buffer;
        return 0;
    }
    
    findStringInstance(0, argv[1],file_buffer,file_size);

    //chiusura del file 
    delete[] file_buffer;
    return 0;
    
}

//noi dobbiamo leggere un file di testo
//scegliere se vofliamo una sola parola o una frase o qualcosa di più
