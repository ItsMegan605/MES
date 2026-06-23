import pandas as pd
import matplotlib.pyplot as plt

RIPETIZIONI = 10
THREAD = 16
TARGET_STRINGS = ["------------", "unevenstring","abracadabra"]
SIZES = [500,1000,2000]

def analizza_e_grafica(csv_file, reps=10, max_threads=16, target_strings=None, file_sizes=None):
    """
    Legge un CSV e genera i grafici confrontando il throughput medio.
    
    Parametri personalizzabili:
    - csv_file: percorso del file CSV.
    - reps: numero massimo di ripetizioni da considerare per la media (default 10).
    - max_threads: numero massimo di thread da mostrare nell'asse X (default 16).
    - target_strings: lista di stringhe specifiche da includere (es. ['abracadabra']). Se None, le usa tutte.
    - file_sizes: lista di dimensioni file da includere (es. [500, 1000]). Se None, le usa tutte.
    """
    
    # 1. Lettura dei dati (impostiamo il separatore col punto e virgola)
    df = pd.read_csv(csv_file, sep=';')
    
    # Pulisce eventuali spazi nei nomi delle colonne
    df.columns = df.columns.str.strip() 
    
    # 2. Applicazione filtri di personalizzazione
    df = df[df['rep'] <= reps]
    df = df[df['thread'] <= max_threads]
    
    if target_strings is not None:
        df = df[df['target_string'].isin(target_strings)]
    if file_sizes is not None:
        df = df[df['file_size'].isin(file_sizes)]
        
    # 3. Calcolo della media delle ripetizioni
    # Raggruppa i dati e calcola la media del throughput per ogni combinazione unica
    mean_df = df.groupby(['file_size', 'target_string', 'thread'])['throughput'].mean().reset_index()
    
    unique_sizes = mean_df['file_size'].unique()
    unique_strings = mean_df['target_string'].unique()
    
    # --- PRIMO SET: Grafici con DIMENSIONE FISSATA (3 grafici, andamenti = stringhe) ---
    for size in unique_sizes:
        plt.figure(figsize=(10, 6))
        
        # Isola i dati solo per la dimensione corrente
        subset_size = mean_df[mean_df['file_size'] == size]
        
        for string in unique_strings:
            # Estrae i dati per la stringa corrente e traccia la funzione
            subset_str = subset_size[subset_size['target_string'] == string]
            if not subset_str.empty:
                plt.plot(subset_str['thread'], subset_str['throughput'], marker='o', label=f'Stringa: {string}')
                
        plt.title(f'Throughput Medio vs Thread (Dimensione File: {size})')
        plt.xlabel('Numero di Thread (1-16)')
        plt.ylabel('Throughput Medio')
        plt.xticks(range(1, max_threads + 1))
        plt.legend(title="Target String")
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        plt.savefig(f'grafico_dimensione_fissa_{size}.png')
        plt.close()

    # --- SECONDO SET: Grafici con STRINGA FISSATA (3 grafici, andamenti = dimensioni) ---
    for string in unique_strings:
        plt.figure(figsize=(10, 6))
        
        # Isola i dati solo per la stringa corrente
        subset_str = mean_df[mean_df['target_string'] == string]
        
        for size in unique_sizes:
            # Estrae i dati per la dimensione corrente e traccia la funzione
            subset_size = subset_str[subset_str['file_size'] == size]
            if not subset_size.empty:
                plt.plot(subset_size['thread'], subset_size['throughput'], marker='s', label=f'Dimensione: {size}')
                
        plt.title(f'Throughput Medio vs Thread (Stringa: {string})')
        plt.xlabel('Numero di Thread (1-16)')
        plt.ylabel('Throughput Medio')
        plt.xticks(range(1, max_threads + 1))
        plt.legend(title="File Size")
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        # Evita problemi nei nomi dei file salvati con i trattini
        safe_string = str(string).replace("-", "dash").replace(" ", "_")
        plt.savefig(f'grafico_stringa_fissa_{safe_string}.png')
        plt.close()

# ==== ESEMPI DI ESECUZIONE ====

# 1. Caso base (usa tutto quello che c'è nel CSV):
# Assegna direttamente il nome del file come stringa
file_name = "originalFull.csv"

# Richiama la funzione
analizza_e_grafica(file_name, RIPETIZIONI, THREAD, TARGET_STRINGS, SIZES)

# 2. Caso personalizzato (solo 5 ripetizioni, max 8 thread, e filtra specifiche stringhe):
# analizza_e_grafica('OptimizedCodeTrialFull.csv', reps=5, max_threads=8, target_strings=['abracadabra', '------------'])
