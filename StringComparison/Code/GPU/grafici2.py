import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Imposta uno stile pulito per i grafici
sns.set_theme(style="whitegrid")

# =========================================================================
# CONFIGURAZIONE CARTELLE
# =========================================================================
# Inserisci qui il nome della cartella che contiene i tuoi file CSV
cartella_input = "csv"  

# Definizione e creazione della cartella principale per i grafici (output)
base_plots_dir = "plots"
os.makedirs(base_plots_dir, exist_ok=True)

# Trova tutti i file CSV all'interno della cartella specificata
path_ricerca = os.path.join(cartella_input, "*.csv")
csv_files = glob.glob(path_ricerca)

if not csv_files:
    print(f"Nessun file CSV trovato nella cartella '{cartella_input}'.")
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
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    df.dropna(subset=['throughput'], inplace=True)
    
    # ---------------------------------------------------------
    # FILTRO: Mantieni SOLO le righe con 'unevenstring'
    # ---------------------------------------------------------
    if 'stringa cercata' in df.columns:
        df = df[df['stringa cercata'] == 'unevenstring']
    
    # Controllo di sicurezza post-filtro
    if df.empty:
        print(f"Salto il file {csv_file}: nessun dato valido rimasto per 'unevenstring'.")
        continue

    # Verifica preliminare delle colonne necessarie (limite shared mem rimosso dai requisiti stretti)
    required_cols = ['stringa cercata', 'thread per blocco', 'throughput']
    if not all(col in df.columns for col in required_cols):
        print(f"Salto il file {csv_file}: colonne necessarie mancanti.")
        continue
        
    # Crea la cartella specifica per questo CSV dentro la cartella base plots
    csv_name = os.path.splitext(os.path.basename(csv_file))[0]
    output_dir = os.path.join(base_plots_dir, csv_name)
    os.makedirs(output_dir, exist_ok=True)
    
    # Calcolo della scala Y fissa basata sull'intero dataset
    t_min = df['throughput'].min()
    t_max = df['throughput'].max()
    ymin = 0 if t_min >= 0 else t_min * 1.1
    ymax = t_max * 1.15 if t_max > 0 else 1.0  # +15% di margine
    
    # Ottieni i valori unici dei thread per impostare le etichette sull'asse X
    unique_threads = sorted(df['thread per blocco'].unique())
    
    # =========================================================================
    # GRAFICO UNICO: Throughput vs Thread per Blocco
    # =========================================================================
    print(f"-> Generazione del grafico unico per Thread per Blocco...")
    
    plt.figure(figsize=(10, 6))
    
    ax = sns.lineplot(
        data=df,
        x="thread per blocco",
        y="throughput",
        marker="o",
        color="royalblue",     # Colore unico poiché non differenziamo per la memoria
        errorbar=('ci', 95),  
        err_style="bars",     
        err_kws={'capsize': 4} 
    )
    
    ax.set_xlabel("Thread per Blocco", fontsize=12)
    ax.set_ylabel("Throughput Medio (con CI 95%)", fontsize=12)
    ax.set_title(f"Throughput al variare dei Thread\n(File: {csv_name} - Dim. 4000MB)", fontsize=14, pad=15)
    
    ax.set_ylim(ymin, ymax)
    ax.set_xticks(unique_threads)
    ax.tick_params(axis='x', rotation=45)
    
    # Salvataggio del singolo grafico
    filename_png = f"{csv_name}_throughput_vs_threads.png"
    filepath = os.path.join(output_dir, filename_png)
    
    plt.savefig(filepath, dpi=300, bbox_inches='tight')
    plt.close()

print(f"\nElaborazione completata! Controlla la cartella '{base_plots_dir}' per i tuoi grafici.")