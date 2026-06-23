import pandas as pd

def estrai_dati(file_input, file_output):
    try:
        # 1. Leggi il file CSV originale specificando il separatore corretto (punto e virgola)
        df = pd.read_csv(file_input, sep=';')
        
        # 2. Verifica la presenza delle colonne necessarie
        if 'dimensione file' not in df.columns or 'stringa cercata' not in df.columns:
            print("Errore: Le colonne 'dimensione file' o 'stringa cercata' non sono presenti nel CSV.")
            return

        # 3. Filtra il DataFrame: dimensione 4000 e stringa "unevenstring"
        df_filtered = df[(df['dimensione file'] == 4000) & (df['stringa cercata'] == 'unevenstring')]
        
        # 4. Salva il risultato in un nuovo file CSV, senza l'indice di riga e mantenendo il separatore
        df_filtered.to_csv(file_output, sep=';', index=False)
        
        print(f"File '{file_output}' generato con successo!")
        print(f"Sono state estratte {len(df_filtered)} righe.")
        
    except Exception as e:
        print(f"Si è verificato un errore: {e}")

if __name__ == "__main__":
    # Nomi dei file
    file_input = "StrideLocal16_results_best_full.csv"
    file_output = "StrideLocal16_4000_unevenstring.csv"
    
    # Esegui la funzione
    estrai_dati(file_input, file_output)
