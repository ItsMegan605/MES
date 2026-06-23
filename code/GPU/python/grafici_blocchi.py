import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
import os
import numpy as np

def main():
    # Verifica l'esistenza dei file CSV
    if not os.path.exists('overhead.csv') or not os.path.exists('memoria.csv'):
        print("Errore: I file CSV non sono stati trovati.")
        return

    df_overhead = pd.read_csv('overhead.csv')
    df_memoria = pd.read_csv('memoria.csv')

    # Ordina per Numero_Blocchi per garantire la continuità della linea
    df_overhead = df_overhead.sort_values(by='Numero_Blocchi').reset_index(drop=True)
    df_memoria = df_memoria.sort_values(by='Numero_Blocchi').reset_index(drop=True)

    # --- SOTTOINSIEME: Ci fermiamo al primo blocco = 24 ---
    if 24 in df_overhead['Numero_Blocchi'].values:
        idx_24_overhead = df_overhead[df_overhead['Numero_Blocchi'] == 24].index[0]
        df_overhead = df_overhead.iloc[:idx_24_overhead + 1].reset_index(drop=True)

    if 24 in df_memoria['Numero_Blocchi'].values:
        idx_24_memoria = df_memoria[df_memoria['Numero_Blocchi'] == 24].index[0]
        df_memoria = df_memoria.iloc[:idx_24_memoria + 1].reset_index(drop=True)

    # ==========================================
    # IMPOSTAZIONI STILE GLOBALE (Stile pulito)
    # ==========================================
    plt.rcParams['font.family'] = 'sans-serif'
    plt.rcParams['axes.axisbelow'] = True
    plt.rcParams['figure.facecolor'] = 'white'
    plt.rcParams['axes.facecolor'] = 'white'
    plt.rcParams['axes.edgecolor'] = '#cccccc'
    plt.rcParams['axes.linewidth'] = 1.2

    line_color = '#4169e1'

    # Array per l'equidistanza sull'asse X
    x_pos_overhead = np.arange(len(df_overhead))
    x_pos_memoria = np.arange(len(df_memoria))

    # ==========================================
    # GRAFICO 1: OVERHEAD
    # ==========================================
    fig1, ax1 = plt.subplots(figsize=(10, 6), dpi=300)
    
    ax1.plot(x_pos_overhead, df_overhead['Overhead_KB'], 
             marker='o', markersize=6, color=line_color, linestyle='-', linewidth=1.5, zorder=3, label='Overhead (KB)')
    
    ax1.axhline(y=100, color='red', linestyle='--', linewidth=1.5, zorder=2, label='Limite Massimo (100 KB)')
    
    ax1.set_title('Overhead al variare dei Blocchi (Fino a 24 blocchi)\n(File: overhead.csv)', fontsize=14, pad=15)
    ax1.set_xlabel('Numero di Blocchi', fontsize=12)
    ax1.set_ylabel('Overhead Medio (KB)', fontsize=12)
    
    ax1.set_ylim(bottom=0)
    ax1.yaxis.set_major_locator(MultipleLocator(10))
    
    ax1.set_xticks(x_pos_overhead)
    ax1.set_xticklabels(df_overhead['Numero_Blocchi'].astype(int))
    
    ax1.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)

    # --- AGGIUNTA ETICHETTE CON I VALORI SUI PUNTI ---
    for i, row in df_overhead.iterrows():
        ax1.annotate(f"{row['Overhead_KB']:.2f} KB",
                     (x_pos_overhead[i], row['Overhead_KB']),
                     textcoords="offset points",
                     xytext=(0, 10),  # Sposta il testo di 10 punti sopra il pallino
                     ha='center',
                     fontsize=9,
                     fontweight='bold',
                     color='#333333')

    plt.setp(ax1.get_yticklabels(), fontsize=11)
    plt.setp(ax1.get_xticklabels(), fontsize=11)
    
    # Sposta la legenda IN ALTO al centro
    ax1.legend(loc='best', frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc')

    plt.tight_layout()
    fig1.savefig('grafico_overhead_blocchi.png')
    plt.close(fig1)

    # ==========================================
    # GRAFICO 2: MEMORIA DISPONIBILE
    # ==========================================
    fig2, ax2 = plt.subplots(figsize=(10, 6), dpi=300)
    
    ax2.plot(x_pos_memoria, df_memoria['Memoria_Disponibile_KB'], 
             marker='o', markersize=6, color=line_color, linestyle='-', linewidth=1.5, zorder=3, label='Memoria Disponibile')
    
    ax2.axhline(y=100, color='green', linestyle='--', linewidth=1.5, zorder=2, label='Memoria Base (100 KB)')
    
    ax2.set_title('Memoria Condivisa Disponibile al variare dei Blocchi\n(File: memoria.csv)', fontsize=14, pad=15)
    ax2.set_xlabel('Numero di Blocchi', fontsize=12)
    ax2.set_ylabel('Memoria Disponibile (KB)', fontsize=12)
    
    ax2.set_ylim(bottom=0)
    ax2.yaxis.set_major_locator(MultipleLocator(10))
    
    ax2.set_xticks(x_pos_memoria)
    ax2.set_xticklabels(df_memoria['Numero_Blocchi'].astype(int))
    
    ax2.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)

    plt.setp(ax2.get_yticklabels(), fontsize=11)
    plt.setp(ax2.get_xticklabels(), fontsize=11)
    
    ax2.legend(frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc')

    plt.tight_layout()
    fig2.savefig('grafico_memoria_blocchi.png')
    plt.close(fig2)

    print("Grafici aggiornati generati con successo!")

if __name__ == "__main__":
    main()