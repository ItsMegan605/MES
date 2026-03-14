#include<iostream>
#include <cstring>
using namespace std;

void build_table(char buf[], int tab[], int len){
    char * head, *tail;
    head = tail = buf;
    int pos = 0;
    tab[0]=0;
    tail++;
    for(int i = 1; i < len; i++){
        if(*tail == *head){
            pos++;
            tab[i] = pos;
            head++;
        }else{
            pos = 0;
            tab[i]=0;
            head = buf;
        }
        tail++;
    }

}
int main(){
    char buf[200];
    int tab[200];
    while(1){
    cout << "Inserisci Parola:\n";
    cin >> buf;
    int len = strlen(buf);
    build_table(buf,tab,len);
    cout << "[ ";
    for(int i = 0; i < len; i++){
        cout << tab[i];
        if(i+1 < len)
            cout <<", ";
    }
    cout << " ]\n";
}
    return 0;
}