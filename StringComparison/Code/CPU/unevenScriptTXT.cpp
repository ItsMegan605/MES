#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <random>
#include <algorithm> 

using namespace std;

int main() {
    // Definizione della dimensione esatta: 4 GB
    const long long TARGET_SIZE = 4000LL * 1024 * 1024; 
    const string filename = "gigante_uneven.txt";
    
    // Dimensione del buffer: 500 MB
    const int BUFFER_SIZE = 500 * 1024 * 1024; 

    // --- PARAMETRI PER LA DISTRIBUZIONE IRREGOLARE ---
    const int N = 12; 
    const int M = 4;  
    const string TARGET_WORD = "uneven";

    // 1. Dizionario SENZA la parola target
    vector<string> words_no_target = {
        "il", "di", "e", "a", "un", "in", "che", "non", "si", "da", "lo", "per", 
        "con", "sono", "come", "ma", "questo", "io", "se", "ha", "le", "su", 
        "anche", "tutto", "era", "quello", "mio", "fare", "hanno", "una", "chi", 
        "cosa", "quando", "molto", "prima", "noi", "essere", "stato", "solo", 
        "due", "dove", "tempo", "vita", "anno", "uomo", "giorno", "poco", "casa", 
        "lavoro", "sempre", "sole", "luna", "mare", "montagna", "fuoco", "albero"
        "acqua", "terra", "gatto", "cane", "macchina", "strada", "cielo", "stella", "culo", "catz",
        "pisello","casa", "lavoro", "sempre", "sole", "luna", "mare", "montagna", "fuoco", 
        "acqua", "terra", "gatto", "cane", "macchina", "forchetta"
    };

    // 2. Dizionario CON la parola target 
    vector<string> words_all = words_no_target;
    words_all.push_back(TARGET_WORD);
    words_all.push_back(TARGET_WORD);

    random_device rd;
    mt19937 rng(rd()); 
    uniform_int_distribution<int> dist_no(0, words_no_target.size() - 1);
    uniform_int_distribution<int> dist_all(0, words_all.size() - 1);
    uniform_int_distribution<int> dist_newline(0, 14);

    long long INTERVAL_SIZE = TARGET_SIZE / N;
    vector<bool> valid_intervals(N, false);
    
    for (int i = 0; i < M && i < N; ++i) {
        valid_intervals[i] = true;
    }
    
    shuffle(valid_intervals.begin(), valid_intervals.end(), rng);

    cout << "Inizio la generazione di " << TARGET_SIZE / (1024 * 1024) << " MB divisa in " << N << " intervalli." << endl;
    cout << "La parola '" << TARGET_WORD << "' potra' comparire SOLO nei seguenti intervalli: ";
    for (int i = 0; i < N; ++i) {
        if (valid_intervals[i]) cout << i + 1 << " ";
    }
    cout << "\n\nPotrebbe volerci qualche minuto..." << endl;

    ofstream outFile(filename, ios::binary);
    if (!outFile) {
        cerr << "Errore critico: Impossibile creare o aprire il file!" << endl;
        return 1;
    }

    long long bytesWritten = 0;
    string buffer;
    buffer.reserve(BUFFER_SIZE + 100); 

    while (bytesWritten < TARGET_SIZE) {
        buffer.clear();
        
        while (buffer.size() < BUFFER_SIZE && (bytesWritten + buffer.size()) < TARGET_SIZE) {
            
            long long current_pos = bytesWritten + buffer.size();
            int current_interval = current_pos / INTERVAL_SIZE;
            if (current_interval >= N) current_interval = N - 1; 

            string next_word;
            
            if (valid_intervals[current_interval]) {
                next_word = words_all[dist_all(rng)];
                
                // --- BLOCCO ANTI-SCONFINAMENTO ---
                // Se abbiamo estratto "albero", verifichiamo che la parola (più lo spazio)
                // non superi fisicamente il confine dell'intervallo attuale.
                if (next_word == TARGET_WORD) {
                    long long end_pos = current_pos + next_word.length() + 1;
                    int next_interval = end_pos / INTERVAL_SIZE;
                    
                    // Se la parola sconfina in un intervallo che è vietato, la sostituiamo
                    if (next_interval < N && !valid_intervals[next_interval]) {
                        next_word = words_no_target[dist_no(rng)];
                    }
                }
            } else {
                next_word = words_no_target[dist_no(rng)];
            }
            
            buffer += next_word + " ";
            
            if (dist_newline(rng) == 0) {
                buffer += "\n";
            }
        }
        
        // --- TRONCAMENTO ESATTO ---
        // Se il buffer ha sforato la dimensione esatta del target, lo tagliamo.
        // Questo garantisce che la divisione in chunk in lettura coincida al byte.
        if (bytesWritten + buffer.size() > TARGET_SIZE) {
            buffer.resize(TARGET_SIZE - bytesWritten);
        }
        
        outFile.write(buffer.c_str(), buffer.size());
        bytesWritten += buffer.size();

        if (bytesWritten % (500LL * 1024 * 1024) < buffer.size()) {
            cout << "Progresso: " << bytesWritten / (1024 * 1024) << " MB scritti su " << TARGET_SIZE / (1024 * 1024) << " MB..." << endl;
        }
    }

    outFile.close();
    cout << "\nOperazione completata con successo!" << endl;
    
    return 0;
}