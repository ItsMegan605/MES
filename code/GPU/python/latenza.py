import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Imposta uno stile pulito per i grafici
sns.set_theme(style="whitegrid")

# Definizione e creazione della nuova cartella principale per i grafici sulla latenza
base_plots_dir = "plots_latenza"
os.makedirs(base_plots_dir, exist_ok=True)

# Trova TUTTI i file CSV nella cartella corrente
csv_files = glob.glob("*.csv")

if not csv_files:
    print("Nessun file CSV trovato nella cartella corrente.")
    exit()

print(f"Trovati {len(csv_files)} file CSV. Inizio l'elaborazione...")

for csv_file in csv_files:
    print(f"\n--------------------------------------------------")
    print(f"Elaborazione del file: {csv_file}")
    print(f"--------------------------------------------------")
    
    try:
        # Lettura del dataset specifico
        df = pd.read_csv(csv_file, sep=';', decimal=',')
    except Exception as e:
        print(f"Errore nella lettura di {csv_file}: {e}")
        continue
        
    # --- CALCOLO LATENZA ---
    # Convertiamo il throughput (Byte/s) in Latenza (secondi) per un file da 7GB
    # 7 GB in Byte = 7 * 1024 * 1024 * 1024
    BYTES_7GB = 7 * 1024 * 1024 * 1024
    df['latenza'] = BYTES_7GB / df['throughput']
    
    # --- GESTIONE NaN e inf ---
    # 1. Sostituiamo gli infiniti (positivi e negativi) generati da divisioni per zero con NaN
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    
    # 2. Rimuoviamo le righe in cui la latenza non è un numero valido
    df.dropna(subset=['latenza'], inplace=True)
    
    # Controllo di sicurezza
    if df.empty:
        print(f"Salto il file {csv_file}: nessun dato valido rimasto dopo la pulizia.")
        continue
    # --------------------------

    # Verifica preliminare delle colonne necessarie
    required_cols = ['stringa cercata', 'thread per blocco', 'dimensione file', 'latenza']
    if not all(col in df.columns for col in required_cols):
        print(f"Salto il file {csv_file}: colonne necessarie mancanti.")
        continue
        
    # Crea la cartella specifica per QUESTO CSV dentro la cartella base
    csv_name = os.path.splitext(os.path.basename(csv_file))[0]
    output_dir = os.path.join(base_plots_dir, csv_name)
    os.makedirs(output_dir, exist_ok=True)
    
    # Calcolo della scala Y fissa basata sull'intero dataset per la LATENZA
    t_min = df['latenza'].min()
    t_max = df['latenza'].max()
    
    # Margine superiore del 50% per non "schiacciare" i grafici (come richiesto)
    ymin = 0 if t_min >= 0 else t_min * 1.1
    ymax = t_max * 1.50 if t_max > 0 else 1.0  
    
    # Ottieni i valori unici per generare i vari grafici
    unique_strings = df['stringa cercata'].unique()
    unique_sizes = df['dimensione file'].unique()
    unique_threads = sorted(df['thread per blocco'].unique())
    
    # =========================================================================
    # GRAFICO 1: GRAFICI INDIVIDUALI
    # =========================================================================
    print(f"-> Generazione grafici singoli per Stringa ({len(unique_strings)} immagini distinte)...")
    for stringa in unique_strings:
        df_sub = df[df['stringa cercata'] == stringa]
        
        if df_sub.empty:
            continue
            
        plt.figure(figsize=(8, 6))
        
        ax = sns.lineplot(
            data=df_sub,
            x="thread per blocco",
            y="latenza",
            hue="dimensione file",
            marker="o",
            palette="viridis",
            errorbar=('ci', 95),  
            err_style="bars",     
            err_kws={'capsize': 4} 
        )
        
        ax.set_xlabel("Thread per Blocco")
        ax.set_ylabel("Latenza Media (secondi) (con CI 95%)")
        ax.set_title(f"Stringa: '{stringa}'\n(Elaborazione 7GB, Linee = Dimensione File MB)")
        ax.set_ylim(ymin, ymax)
        ax.set_xticks(unique_threads)
        ax.tick_params(axis='x', rotation=45)
        ax.legend(title="dimensione file", bbox_to_anchor=(1.05, 1), loc='upper left')
        
        safe_stringa = "".join([c if c.isalnum() or c in (' ', '_', '-') else '_' for c in str(stringa)]).strip()
        filename_png = f"grafico_latenza_singolo_{safe_stringa}.png"
        filepath = os.path.join(output_dir, filename_png)
        
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
    # =========================================================================
    # GRAFICO 2: GRAFICO COMPLETO 
    # =========================================================================
    print(f"-> Generazione grafico COMPLETO per Dimensione File ({len(unique_sizes)} immagini distinte)...")
    for dimensione in unique_sizes:
        df_sub = df[df['dimensione file'] == dimensione]
        
        if df_sub.empty:
            continue
            
        plt.figure(figsize=(8, 6))
        
        ax = sns.lineplot(
            data=df_sub,
            x="thread per blocco",
            y="latenza",
            hue="stringa cercata", 
            marker="o",
            palette="tab10",
            errorbar=('ci', 95),   
            err_style="bars",      
            err_kws={'capsize': 4}  
        )
        
        ax.set_xlabel("Thread per Blocco")
        ax.set_ylabel("Latenza Media (secondi) (con CI 95%)")
        ax.set_title(f"Confronto Completo - Dimensione File: {dimensione} MB\n(Elaborazione 7GB)")
        
        ax.set_ylim(ymin, ymax)
        ax.set_xticks(unique_threads)
        ax.tick_params(axis='x', rotation=45)
        ax.legend(title="stringa cercata", bbox_to_anchor=(1.05, 1), loc='upper left')
        
        filename_png = f"grafico_latenza_completo_{dimensione}MB.png"
        filepath = os.path.join(output_dir, filename_png)
        
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()

print(f"\nElaborazione completata per tutti i file! Controlla la cartella '{base_plots_dir}'.")