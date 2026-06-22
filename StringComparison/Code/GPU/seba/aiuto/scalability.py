import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.ticker as ticker

# ==========================================
# IMPOSTAZIONI GLOBALI
# ==========================================
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['axes.axisbelow'] = True
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['axes.facecolor'] = 'white'
plt.rcParams['axes.edgecolor'] = '#cccccc'
plt.rcParams['axes.linewidth'] = 1.2

def genera_grafici_scalabilita(file_csv):
    try:
        df = pd.read_csv(file_csv, sep=';', decimal=',')
    except Exception as e:
        print(f"Errore nella lettura del file: {e}")
        return

    # Pulizia dati base
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    df.dropna(subset=['throughput'], inplace=True)
    
    # Conversione throughput in GB/s
    df['throughput'] = df['throughput'] / 1e9

    # Gestione nome colonna dimensione
    col_dim = 'dimensione file' if 'dimensione file' in df.columns else 'dimensione'
    if col_dim not in df.columns:
        print("Errore: Impossibile trovare la colonna relativa alla dimensione del file.")
        return

    if df.empty:
        print("Il dataframe è vuoto.")
        return

    print(f"Dati letti. Righe rimanenti: {len(df)}")

    # ==========================================
    # FORMATTAZIONE COLONNA DIMENSIONE PER LEGENDA E TITOLI
    # ==========================================
    df[f'{col_dim}_label'] = df[col_dim].apply(
        lambda x: f"{int(x/1000)} GB" if x % 1000 == 0 else f"{x/1000:.1f} GB"
    )
    col_dim_label = f'{col_dim}_label'

    # ==========================================
    # PLOT 1: Fissa la stringa, varia la dimensione
    # ==========================================
    stringhe_uniche = df['stringa cercata'].unique()
    
    for stringa in stringhe_uniche:
        if stringa != "unevenstring":
            continue
        df_subset = df[df['stringa cercata'] == stringa]
        
        fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
        sns.lineplot(
            data=df_subset,
            x='thread per blocco',
            y='throughput',
            hue=col_dim_label,
            marker="o",
            markersize=8,
            linewidth=2,
            errorbar=('ci', 95),
            err_style="bars",
            err_kws={'capsize': 5},
            ax=ax,
            palette="tab10"
        )
        
        ax.set_title(f"Scalability - String: '{stringa}'", fontsize=16, pad=15, fontweight='bold')
        ax.set_xlabel("Threads per Block", fontsize=15, labelpad=10)
        ax.set_ylabel("Throughput (GB/s)", fontsize=15, labelpad=11)
        ax.tick_params(axis='both', which='major', labelsize=13)
        ax.set_xticks(sorted(df['thread per blocco'].unique()))
        ax.set_ylim(0)
        ax.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1)
        ax.legend(title="File Size:", fontsize=11, title_fontsize=12)
        
        plt.tight_layout()
        nome_file_out = f"scalability_stringa_{stringa}.svg"
        fig.savefig(nome_file_out, format='svg')
        plt.close(fig)
        print(f"Generato: {nome_file_out}")

    # ==========================================
    # PLOT 2: Fissa la dimensione, varia la stringa
    # ==========================================
    dimensioni_uniche = df[col_dim].unique()
    
    for dimensione in dimensioni_uniche:
        if dimensione != 4000:
            continue
            
        df_subset = df[df[col_dim] == dimensione]
        dimensione_label = df_subset[col_dim_label].iloc[0]
        
        fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
        sns.lineplot(
            data=df_subset,
            x='thread per blocco',
            y='throughput',
            hue='stringa cercata',
            marker="o",
            markersize=8,
            linewidth=2,
            errorbar=('ci', 95),
            err_style="bars",
            err_kws={'capsize': 5},
            ax=ax,
            palette="Set1"
        )
        
        ax.set_title(f"Scalability - File Size: {dimensione_label}", fontsize=16, pad=15, fontweight='bold')
        ax.set_xlabel("Threads per Block", fontsize=15, labelpad=10)
        ax.set_ylabel("Throughput (GB/s)", fontsize=15, labelpad=10)
        ax.tick_params(axis='both', which='major', labelsize=11)
        
        ax.set_xticks(sorted(df['thread per blocco'].unique()))
        
        # Granularità asse Y a 25 per questo grafico
        ax.yaxis.set_major_locator(ticker.MultipleLocator(25))
        
        ax.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1)
        ax.legend(title="String:", fontsize=11, title_fontsize=12)
        ax.set_ylim(0)
        
        plt.tight_layout()
        nome_file_out = f"scalability_dimensione_{dimensione}.svg"
        fig.savefig(nome_file_out, format='svg')
        plt.close(fig)
        print(f"Generato: {nome_file_out}")

if __name__ == "__main__":
    file_input = "StrideLocal16_results.csv" 
    genera_grafici_scalabilita(file_input)
