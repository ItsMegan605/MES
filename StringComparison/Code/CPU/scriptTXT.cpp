#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <random>

using namespace std;

int main() {
    // Definizione della dimensione: 5 GB = 5 * 1024 * 1024 * 1024 byte
    const long long TARGET_SIZE = 4000LL  * 1024 * 1024; 
    const string filename = "gigante.txt";
    
    // Dimensione del buffer: 500 MB (scrivere a blocchi grandi è molto più veloce)
    const int BUFFER_SIZE = 500* 1024 * 1024; 

    // Un dizionario di base con "parole sensate". Puoi aggiungerne quante ne vuoi.
    vector<string> words = {
        "il", "di", "e", "a", "un", "in", "che", "non", "si", "da", "lo", "per", 
        "con", "sono", "come", "ma", "questo", "io", "se", "ha", "le", "su", 
        "anche", "tutto", "era", "quello", "mio", "fare", "hanno", "una", "chi", 
        "cosa", "quando", "molto", "prima", "noi", "essere", "stato", "solo", 
        "due", "dove", "tempo", "vita", "anno", "uomo", "giorno", "poco", "casa", 
        "lavoro", "sempre", "sole", "luna", "mare", "montagna", "albero", "fuoco",
        "acqua", "terra", "gatto", "cane", "macchina", "strada", "cielo", "stella", "culo", "catz",
        "pisello","casa", "lavoro", "sempre", "sole", "luna", "mare", "montagna", "albero", "fuoco",
        "acqua", "terra", "gatto", "cane", "macchina", "forchetta"
    };

    // Apertura del file in modalità binaria per massimizzare la velocità di scrittura
    ofstream outFile(filename, ios::binary);
    if (!outFile) {
        cerr << "Errore critico: Impossibile creare o aprire il file!" << endl;
        return 1;
    }

    // Impostazione del generatore di numeri casuali (molto più veloce e sicuro di rand())
    random_device rd;
    mt19937 rng(rd()); 
    uniform_int_distribution<int> dist(0, words.size() - 1);

    long long bytesWritten = 0;
    string buffer;
    
    // Riserviamo in anticipo la memoria per il buffer per evitare riallocazioni lente
    buffer.reserve(BUFFER_SIZE + 100); 

    cout << "Inizio la generazione del file da "<< TARGET_SIZE/(1024 * 1024) << "MB. Potrebbe volerci qualche minuto..." << endl;

    while (bytesWritten < TARGET_SIZE) {
        buffer.clear();
        
        // Riempi il buffer fino ad arrivare a circa 1 MB
        while (buffer.size() < BUFFER_SIZE) {
            buffer += words[dist(rng)] + " ";
            
            // Ogni tanto, al posto dello spazio, inseriamo un 'a capo' per formattare meglio il testo
            if (dist(rng) % 15 == 0) {
                buffer += "\n";
            }
        }
        
        // Scrivi l'intero blocco da 1 MB sul disco
        outFile.write(buffer.c_str(), buffer.size());
        bytesWritten += buffer.size();

        // Stampa un aggiornamento ogni 500 MB scritti per far capire all'utente che il programma sta lavorando
        if (bytesWritten % (500LL * 1024 * 1024) < buffer.size()) {
            cout << "Progresso: " << bytesWritten / (1024 * 1024) << " MB scritti su 5120 MB..." << endl;
        }
    }

    outFile.close();
    cout << "\nOperazione completata con successo! Il file '" << filename << "' e' pronto." << endl;
    
    return 0;
}