import pandas as pd
import matplotlib.pyplot as plt

RIPETIZIONI = 10
THREAD = 16
TARGET_STRINGS = ["------------", "unevenstring","abracadabra"]
SIZES = [500,1000,2000]

def analizza_e_grafica_speedup(csv_file, reps=10, max_threads=16, target_strings=None, file_sizes=None):
    """
    Legge un CSV e genera i grafici confrontando lo speedup medio.
    Lo speedup è calcolato come Throughput(n thread) / Throughput(1 thread).
    """
    
    # 1. Lettura dei dati
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
    mean_df = df.groupby(['file_size', 'target_string', 'thread'])['throughput'].mean().reset_index()
    
    # 4. Calcolo dello Speedup
    # Estraiamo i valori di throughput con 1 thread (T1) per ogni gruppo
    t1_df = mean_df[mean_df['thread'] == 1][['file_size', 'target_string', 'throughput']]
    t1_df = t1_df.rename(columns={'throughput': 'throughput_1'})
    
    # Uniamo i dati con T1 e calcoliamo lo speedup
    mean_df = pd.merge(mean_df, t1_df, on=['file_size', 'target_string'])
    mean_df['speedup'] = mean_df['throughput'] / mean_df['throughput_1']
    
    unique_sizes = mean_df['file_size'].unique()
    unique_strings = mean_df['target_string'].unique()
    
    # Assi di riferimento per il grafico (da 1 a max_threads)
    assi_ticks = range(1, max_threads + 1)
    
    # --- PRIMO SET: Grafici con DIMENSIONE FISSATA (andamenti = stringhe) ---
    for size in unique_sizes:
        plt.figure(figsize=(10, 8))
        
        subset_size = mean_df[mean_df['file_size'] == size]
        
        for string in unique_strings:
            subset_str = subset_size[subset_size['target_string'] == string]
            if not subset_str.empty:
                plt.plot(subset_str['thread'], subset_str['speedup'], marker='o', label=f'Stringa: {string}')
        
        # Aggiunta retta bisettrice (Speedup Ideale)
        plt.plot(assi_ticks, assi_ticks, 'k--', linewidth=2, label='Speedup Ideale (y=x)')
                
        plt.title(f'Speedup vs Thread (Dimensione File: {size})')
        plt.xlabel('Numero di Thread')
        plt.ylabel('Speedup')
        
        # Imposta i limiti e i tick degli assi X e Y per essere da 1 a 16
        plt.xlim(1, max_threads)
        plt.ylim(1, max_threads)
        plt.xticks(assi_ticks)
        plt.yticks(assi_ticks)
        
        plt.legend(title="Target String")
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        plt.savefig(f'speedup_dimensione_fissa_{size}.png')
        plt.close()

    # --- SECONDO SET: Grafici con STRINGA FISSATA (andamenti = dimensioni) ---
    for string in unique_strings:
        plt.figure(figsize=(10, 8))
        
        subset_str = mean_df[mean_df['target_string'] == string]
        
        for size in unique_sizes:
            subset_size = subset_str[subset_str['file_size'] == size]
            if not subset_size.empty:
                plt.plot(subset_size['thread'], subset_size['speedup'], marker='s', label=f'Dimensione: {size}')
                
        # Aggiunta retta bisettrice (Speedup Ideale)
        plt.plot(assi_ticks, assi_ticks, 'k--', linewidth=2, label='Speedup Ideale (y=x)')
                
        plt.title(f'Speedup vs Thread (Stringa: {string})')
        plt.xlabel('Numero di Thread')
        plt.ylabel('Speedup')
        
        # Imposta i limiti e i tick degli assi X e Y per essere da 1 a 16
        plt.xlim(1, max_threads)
        plt.ylim(1, max_threads)
        plt.xticks(assi_ticks)
        plt.yticks(assi_ticks)
        
        plt.legend(title="File Size")
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        safe_string = str(string).replace("-", "dash").replace(" ", "_")
        plt.savefig(f'speedup_stringa_fissa_{safe_string}.png')
        plt.close()

# ==== ESEMPI DI ESECUZIONE ====

if __name__ == "__main__":
    file_name = "originalFull.csv"  # Rimosso input()
    analizza_e_grafica_speedup(file_name, RIPETIZIONI, THREAD, TARGET_STRINGS, SIZES)