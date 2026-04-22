#include "shared.h"

// this file contains all the code shared between the various versions, main included

void findStringIstance(int, int); // this function will be different depending on which program is run

void debug_print(int thread_index, chrono::steady_clock::time_point start, unsigned int local_occurrences){

    chrono::steady_clock::time_point end = chrono::steady_clock::now();
    chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);

    output_mtx.lock();
    cout << "Th " << thread_index << " time: " << duration.count() << " ms | Occurrences: "  << local_occurrences << endl;
    output_mtx.unlock();
}

void build_table(int len){

    char * head, *tail;
    head = tail = target_string;
    
    
    longest_prefix_suffix_array[0]=0; // the first element is always 0, therefore ...
    tail++; // ... we start from the second element
    
    int pos = 0;

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


//creation and thread waiting
void parallelStringSearch(int num_threads) {

    vector<thread> threads;

    for(int i = 0; i < num_threads-1; i++){
        threads.emplace_back(findStringIstance, i, 0);
    }
    findStringIstance(num_threads-1, file_size%num_threads); //main thread is the last one
    for(auto& t : threads){
        t.join(); //wait for threads to finish
    }

    #ifdef DEBUG

        occurrences += atomic_occurrences;
        cout << "Occurrences of \"" << target_string << "\": " << occurrences<< endl;
    
    #endif
}


int main(int argc, char* argv[]) {

    if (argc < 3) {
        cout << "Insert the target string and the number of threads as arguments, and (optional) a file limit expressed in MBs." << endl;
        return 1;
    }

    target_string = argv[1]; //word to compare, taken from terminal
    num_threads = stoi(argv[2]); //number of threads, taken from terminal  

    try {
        file_size = fs::file_size(FILE_PATH);

    } catch (const fs::filesystem_error& e) {
        
        cerr << "Can't read the file: " << e.what() << '\n';
        return 1;
    }

    if(argc > 3){
        std::uintmax_t file_limit = std::strtoull(argv[3], nullptr, 10)*1024*1024;
        file_size = (file_limit < file_size)? file_limit : file_size;
    }

    chunk_size = file_size / num_threads; //static chunk size for each thread

    std::ifstream file(FILE_PATH, std::ios::binary);
    
    if (!file) {
        cerr << "Error: the file couldn't be opened.\n";
        return 1;
    }
    file_buffer = new char[file_size];
    end_of_file = file_buffer + file_size + 1;

    // we read one file block at the time, due to windows file size constraints
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

    // we build the lps array, used by the kmp string match algorythm
    int target_string_len = strlen(target_string); 
    longest_prefix_suffix_array = new int[target_string_len];
    build_table(target_string_len);

    chrono::steady_clock::time_point start = chrono::steady_clock::now();
    
    parallelStringSearch(num_threads);
    
    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    chrono::milliseconds duration = chrono::duration_cast<chrono::milliseconds>(end - start);
    
    #ifdef DEBUG

        cout<<"Total duration: " << duration.count() / (double) 1000 << " s | Throughput: ";
    
    #endif
    
    cout << ((double)file_size / duration.count())* 1000 << endl;

    //end of file
    delete[] longest_prefix_suffix_array;
    delete[] file_buffer;
    return 0;
    
}