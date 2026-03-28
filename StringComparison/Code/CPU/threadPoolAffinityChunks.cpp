#include <iostream>
#include <thread>
#include <mutex>
#include <vector>
#include <queue>
#include <condition_variable>
#include <functional>
#include <chrono>
#include <windows.h>

#define CHUNK_SIZE 2

using namespace std;

mutex mtx;
mutex out;

uintmax_t next_chunk_start = 0;

const uintmax_t file_size = 2000 * CHUNK_SIZE;

size_t num_threads = 8;

class ThreadPool {
private:
    vector<thread> workers;
    queue<function<void(int)>> tasks;
    
    mutex queue_mutex;
    condition_variable condition;
    
    bool stop = false;
    bool start_working = false;

public:
    ThreadPool(size_t num_threads = 0){
        if(num_threads > 0)
            this->buildPool(num_threads);
    }

// Costruttore: crea i thread, ma li mette subito in pausa
    void buildPool(size_t num_threads) {
        for(size_t i = 0; i < num_threads; ++i) {
            workers.emplace_back([this, i] { //tutto quello dentro questa graffa è eseguito dal thread
                //while(true) { commentato in quanto il thread fa solo una sola iterazione
                    function<void(int)> task;
                    
                    {
                        unique_lock<mutex> lock(this->queue_mutex);
                        
                        this->condition.wait(lock, [this] {
                            return this->stop || (this->start_working && !this->tasks.empty());
                        });
                        
                        // Se la pool è stata fermata e la coda è vuota, esci
                        if(this->stop && this->tasks.empty())
                            return;
                            
                        // Estrai il task dalla coda
                        task = move(this->tasks.front());
                        this->tasks.pop();
                    }
                    // Esegui il task (fuori dal lock per non bloccare gli altri thread)
                    task(i);

                    
                //}
            });
            DWORD_PTR dw = SetThreadAffinityMask(workers.back().native_handle(), DWORD_PTR(1) << i + 1); // i + 1 e non i perche almeno lascio il primo core al main 
            if (dw == 0) {
                DWORD dwErr = GetLastError();
                cerr << "SetThreadAffinityMask failed, GLE=" << dwErr << '\n';
            }
        }
    }

    // Aggiunge un task alla coda
    void enqueue(function<void(int)> task) {
        {
            unique_lock<mutex> lock(queue_mutex);
            tasks.push(task);
        }
        // Sveglia un thread (anche se non farà nulla se start_working è ancora false)
        condition.notify_one(); 
    }

    // IL TUO COMANDO PER FARLI PARTIRE
    void start() {
        {
            unique_lock<mutex> lock(queue_mutex);
            start_working = true;
        }
        // Sveglia TUTTI i thread contemporaneamente
        condition.notify_all();
    }

    void wait() {
    for (thread& w : workers) {
        w.join();
    }
}

    // Distruttore per pulire tutto in sicurezza
    ~ThreadPool() {
        {
            unique_lock<mutex> lock(queue_mutex);
            stop = true;
            start_working = true; // Necessario se distruggi prima di chiamare start()
        }
        condition.notify_all();
        for(thread &worker : workers) {
            if(worker.joinable()) {
                worker.join();
            }
        }
    }
};

uintmax_t getNextChunkStart(){
    uintmax_t aux;
    lock_guard<mutex> locker(mtx);
    aux = next_chunk_start;
    next_chunk_start += CHUNK_SIZE;

    return aux;
}

void work(int index){
    unique_lock<mutex> output(out);
    cout<<"ciao, sono id: " <<index <<endl;
    output.unlock();
    int quanti = 0;
    while(true){
        uintmax_t my_piece = getNextChunkStart();
        if(my_piece >= file_size){
            output.lock();
            cout<<index<<") il file e' finito :(  ho operato su "<<quanti<<" pezzi"<<endl;
            output.unlock();
            break;
        }

        quanti++;
        
        output.lock();
        cout<<index<<") ho preso il pezzo " << my_piece << ", inizio operazioni..."<<endl;
        output.unlock();

        for(volatile int i = 0; i < 10000000; i++);
    }
}

void culo(ThreadPool &pool){
    pool.start();
    work(num_threads-1);
    pool.wait();
}

int main(){
    
    // Set the affinity mask for the Main Thread
    DWORD_PTR dw = SetThreadAffinityMask(GetCurrentThread(), DWORD_PTR(1));
    if (dw == 0) {
        DWORD dwErr = GetLastError();
        cerr << "SetThreadAffinityMask failed, GLE=" << dwErr << '\n';
    
    }
    ThreadPool pool;
    pool.buildPool(num_threads-1);
    for(int i = 0; i < num_threads-1; i++)
        pool.enqueue(work);
    
    culo(pool);

    // il main thread non aspetta qua.
    return 0;
}

