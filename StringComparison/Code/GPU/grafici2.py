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
    # In questo modo evitiamo crolli a zero, oscillazioni e medie sballate.
    df.dropna(subset=['throughput'], inplace=True)
    
    # Controllo di sicurezza: se dopo la pulizia il file è vuoto, lo saltiamo
    if df.empty:
        print(f"Salto il file {csv_file}: nessun dato valido rimasto dopo la pulizia da inf/NaN.")
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
    
    # Per garantire la stessa scala (asse Y) tra tutti i grafici di questo specifico file,
    # calcoliamo il minimo e il massimo globale del throughput includendo un margine per i CI
    t_min = df['throughput'].min()
    t_max = df['throughput'].max()
    ymin = 0 if t_min >= 0 else t_min * 1.1
    ymax = t_max * 1.15 if t_max > 0 else 1.0  # +15% di margine per non tagliare le bande di confidenza
    
    # Ottieni i valori unici per i cicli
    unique_strings = df['stringa cercata'].unique()
    unique_sizes = df['dimensione file'].unique()
    unique_threads = sorted(df['thread per blocco'].unique())
    
    # =========================================================================
    # GRAFICO 1: FISSIAMO LA STRINGA (Immagini separate, stessa scala)
    # =========================================================================
    print(f"-> Generazione grafici per Stringa ({len(unique_strings)} immagini distinte)...")
    for stringa in unique_strings:
        df_sub = df[df['stringa cercata'] == stringa]
        
        # Se non ci sono dati per questa combinazione (magari rimossi dalla pulizia), salta
        if df_sub.empty:
            continue
            
        plt.figure(figsize=(8, 6)) # Inizializza la figura per evitare sovrapposizioni
        
        # Genera il grafico a linee con intervallo di confidenza a BARRE (linee verticali)
        ax = sns.lineplot(
            data=df_sub,
            x="thread per blocco",
            y="throughput",
            hue="dimensione file",
            marker="o",
            palette="viridis",
            errorbar=('ci', 95),  # Calcola l'intervallo di confidenza al 95% sulle run
            err_style="bars",     # Disegna l'intervallo come linee e non come banda sfumata
            err_kws={'capsize': 4} # Aggiunge i "cappelli" orizzontali agli estremi delle linee
        )
        
        # Configurazione assi e titoli
        ax.set_xlabel("Thread per Blocco")
        ax.set_ylabel("Throughput Medio (con CI 95%)")
        ax.set_title(f"Stringa: '{stringa}'\n(Linee = Dimensione File MB)")
        
        # Applica la scala fissa calcolata globalmente per il file corrente
        ax.set_ylim(ymin, ymax)
        ax.set_xticks(unique_threads)
        ax.tick_params(axis='x', rotation=45)
        
        # Posiziona la legenda all'esterno a destra per evitare sovrapposizioni
        ax.legend(title="dimensione file", bbox_to_anchor=(1.05, 1), loc='upper left')
        
        # Sanatizzazione del nome della stringa per il nome del file PNG
        safe_stringa = "".join([c if c.isalnum() or c in (' ', '_', '-') else '_' for c in str(stringa)]).strip()
        filename_png = f"grafico_stringa_{safe_stringa}.png"
        filepath = os.path.join(output_dir, filename_png)
        
        # Salvataggio e chiusura della figura corrente
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
    # =========================================================================
    # GRAFICO 2: FISSIAMO LA DIMENSIONE DEL FILE (Immagini separate, stessa scala)
    # =========================================================================
    print(f"-> Generazione grafici per Dimensione File ({len(unique_sizes)} immagini distinte)...")
    for dimensione in unique_sizes:
        df_sub = df[df['dimensione file'] == dimensione]
        
        # Se non ci sono dati per questa combinazione, salta
        if df_sub.empty:
            continue
            
        plt.figure(figsize=(8, 6))
        
        # Genera il grafico a linee con intervallo di confidenza a BARRE
        ax = sns.lineplot(
            data=df_sub,
            x="thread per blocco",
            y="throughput",
            hue="stringa cercata",
            marker="o",
            palette="tab10",
            errorbar=('ci', 95),   
            err_style="bars",      
            err_kws={'capsize': 4}  
        )
        
        # Configurazione assi e titoli
        ax.set_xlabel("Thread per Blocco")
        ax.set_ylabel("Throughput Medio (con CI 95%)")
        ax.set_title(f"Dimensione File: {dimensione} MB\n(Linee = Stringa)")
        
        # Applica la stessa scala fissa calcolata globalmente per il file corrente
        ax.set_ylim(ymin, ymax)
        ax.set_xticks(unique_threads)
        ax.tick_params(axis='x', rotation=45)
        
        # Posiziona la legenda all'esterno a destra
        ax.legend(title="stringa cercata", bbox_to_anchor=(1.05, 1), loc='upper left')
        
        filename_png = f"grafico_dimensione_{dimensione}MB.png"
        filepath = os.path.join(output_dir, filename_png)
        
        # Salvataggio e chiusura della figura
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()

print(f"\nElaborazione completata! Controlla la cartella '{base_plots_dir}' per vedere i risultati suddivisi.")