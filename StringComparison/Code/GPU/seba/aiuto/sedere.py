import pandas as pd

def main():
    file_name = 'StrideLocal16_results.csv'
    
    # Lettura del file CSV
    df = pd.read_csv(file_name, sep=';')
    
    # Rimozione delle righe con dimensione file pari a 3000
    df_filtered = df[df['dimensione file'] != 5000]
    
    # Sovrascrittura del file originale
    df_filtered.to_csv(file_name, sep=';', index=False)
    
    print(f"Operazione completata. Righe originali: {len(df)}, Righe rimanenti: {len(df_filtered)}")

if __name__ == "__main__":
    main()
