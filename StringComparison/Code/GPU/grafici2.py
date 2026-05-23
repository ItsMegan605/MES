import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Imposta uno stile pulito per i grafici
sns.set_theme(style="whitegrid")

# Definizione e creazione della cartella principale per i grafici
base_plots_dir = "plots"
os.makedirs(base_plots_dir, exist_ok=True)

# Trova tutti i file CSV nella cartella corrente
csv_files = glob.glob("*.csv")

if not csv_files:
    print("Nessun file CSV trovato nella cartella corrente.")
    exit()

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
        
    # --- GESTIONE NaN e inf ---
    # 1. Sostituiamo gli infiniti (positivi e negativi) con NaN
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    
    # 2. Rimuoviamo le righe in cui il throughput non è un numero valido.
    df.dropna(subset=['throughput'], inplace=True)
    
    # Controllo di sicurezza
    if df.empty:
        print(f"Salto il file {csv_file}: nessun dato valido rimasto dopo la pulizia.")
        continue
    # --------------------------

    # Verifica preliminare delle colonne necessarie
    required_cols = ['stringa cercata', 'thread per blocco', 'dimensione file', 'throughput']
    if not all(col in df.columns for col in required_cols):
        print(f"Salto il file {csv_file}: colonne necessarie mancanti.")
        continue
        
    # Crea la cartella specifica per questo CSV dentro la cartella base
    csv_name = os.path.splitext(os.path.basename(csv_file))[0]
    output_dir = os.path.join(base_plots_dir, csv_name)
    os.makedirs(output_dir, exist_ok=True)
    
    # Calcolo della scala Y fissa basata sull'intero dataset (permette di confrontare
    # a occhio grafici diversi dello stesso file senza farsi ingannare dagli assi)
    t_min = df['throughput'].min()
    t_max = df['throughput'].max()
    ymin = 0 if t_min >= 0 else t_min * 1.1
    ymax = t_max * 1.15 if t_max > 0 else 1.0  # +15% di margine
    
    # Ottieni i valori unici per generare i vari grafici
    unique_strings = df['stringa cercata'].unique()
    unique_sizes = df['dimensione file'].unique()
    unique_threads = sorted(df['thread per blocco'].unique())
    
    # =========================================================================
    # GRAFICO 1: GRAFICI INDIVIDUALI (Es: solo 'abracadabra', solo 'unevenstring', ecc.)
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
            y="throughput",
            hue="dimensione file",
            marker="o",
            palette="viridis",
            errorbar=('ci', 95),  
            err_style="bars",     
            err_kws={'capsize': 4} 
        )
        
        ax.set_xlabel("Thread per Blocco")
        ax.set_ylabel("Throughput Medio (con CI 95%)")
        ax.set_title(f"Stringa: '{stringa}'\n(Linee = Dimensione File MB)")
        ax.set_ylim(ymin, ymax)
        ax.set_xticks(unique_threads)
        ax.tick_params(axis='x', rotation=45)
        ax.legend(title="dimensione file", bbox_to_anchor=(1.05, 1), loc='upper left')
        
        safe_stringa = "".join([c if c.isalnum() or c in (' ', '_', '-') else '_' for c in str(stringa)]).strip()
        filename_png = f"grafico_singolo_{safe_stringa}.png"
        filepath = os.path.join(output_dir, filename_png)
        
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
    # =========================================================================
    # GRAFICO 2: GRAFICO COMPLETO (Tutte e 3 le stringhe a confronto per ogni file)
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
            y="throughput",
            hue="stringa cercata", # Qui crea le 3 linee diverse nello stesso grafico
            marker="o",
            palette="tab10",
            errorbar=('ci', 95),   
            err_style="bars",      
            err_kws={'capsize': 4}  
        )
        
        ax.set_xlabel("Thread per Blocco")
        ax.set_ylabel("Throughput Medio (con CI 95%)")
        ax.set_title(f"Confronto Completo - Dimensione File: {dimensione} MB\n(Tutte le stringhe)")
        
        ax.set_ylim(ymin, ymax)
        ax.set_xticks(unique_threads)
        ax.tick_params(axis='x', rotation=45)
        ax.legend(title="stringa cercata", bbox_to_anchor=(1.05, 1), loc='upper left')
        
        filename_png = f"grafico_completo_confronto_{dimensione}MB.png"
        filepath = os.path.join(output_dir, filename_png)
        
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()

print(f"\nElaborazione completata! Controlla la cartella '{base_plots_dir}' per i tuoi grafici singoli e completi.")