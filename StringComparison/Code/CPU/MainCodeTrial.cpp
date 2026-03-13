#include <iostream>
#include <string>

using namespace std;

#define FILENAME "esempio.txt"


//intanto mettiamo le cose nell main poi fare funzini esterne

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cout << "Insert at least one word as an argument." << endl;
        return 1;
    }

    //prendere la stringa da terminale 
    char* inputString = argv[1]; //prende la prima parola passata come argomento


    //apertura del file di testo
   
    FILE* file = fopen(FILENAME, "r"); //apertura del file in modalità lettura
    if (file == nullptr) {
        cout << "Error opening file: " << FILENAME << endl;
        return 1;
    }

    //operazioni per fare il compare


    //chiusura del file 
    fclose(file);
    return 0;
    
}

//noi dobbiamo leggere un file di testo
//scegliere se vofliamo una sola parola o una frase o qualcosa di più
