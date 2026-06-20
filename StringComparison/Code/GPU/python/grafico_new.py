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

    # Filtriamo PRIMA tenendo solo le righe con Numero_Blocchi <= 24
    df_overhead = df_overhead[df_overhead['Numero_Blocchi'] <= 24].copy()
    df_memoria = df_memoria[df_memoria['Numero_Blocchi'] <= 24].copy()

    # ORA ordiniamo per THREAD, per mostrare l'andamento all'aumentare dei thread
    df_overhead = df_overhead.sort_values(by='Threads').reset_index(drop=True)
    df_memoria = df_memoria.sort_values(by='Threads').reset_index(drop=True)

    # ==========================================
    # IMPOSTAZIONI STILE GLOBALE
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

    # Creazione delle etichette DOPPIE per l'asse X (es. "32 Thr\n(24 blk)")
    labels_x_overhead = [f"{int(row['Threads'])} Thr\n({int(row['Numero_Blocchi'])} blk)" for _, row in df_overhead.iterrows()]
    labels_x_memoria = [f"{int(row['Threads'])} Thr\n({int(row['Numero_Blocchi'])} blk)" for _, row in df_memoria.iterrows()]

    # ==========================================
    # GRAFICO 1: OVERHEAD
    # ==========================================
    fig1, ax1 = plt.subplots(figsize=(11, 6), dpi=300)
    
    ax1.plot(x_pos_overhead, df_overhead['Overhead_KB'], 
             marker='o', markersize=6, color=line_color, linestyle='-', linewidth=1.5, zorder=3, label='Overhead (KB)')
    
    ax1.axhline(y=100, color='red', linestyle='--', linewidth=1.5, zorder=2, label='Limite Massimo (100 KB)')
    
    ax1.set_title('Overhead al variare della configurazione (Max 24 blocchi)\n(File: overhead.csv)', fontsize=14, pad=15)
    ax1.set_xlabel('Configurazione (Thread per Blocco -> Blocchi Max)', fontsize=12, labelpad=10)
    ax1.set_ylabel('Overhead Medio (KB)', fontsize=12)
    
    # Impostiamo il limite superiore dell'asse Y a 130
    ax1.set_ylim(bottom=0, top=110)
    ax1.yaxis.set_major_locator(MultipleLocator(10))
    
    ax1.set_xticks(x_pos_overhead)
    ax1.set_xticklabels(labels_x_overhead)
    
    ax1.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)

    # Etichette dei valori sopra i punti
    for i, row in df_overhead.iterrows():
        ax1.annotate(f"{row['Overhead_KB']:.2f} KB",
                     (x_pos_overhead[i], row['Overhead_KB']),
                     textcoords="offset points",
                     xytext=(7, 10),
                     ha='center',
                     fontsize=9,
                     fontweight='bold',
                     color='#333333')

    plt.setp(ax1.get_yticklabels(), fontsize=11)
    
    # Meno inclinazione per le doppie etichette
    plt.setp(ax1.get_xticklabels(), rotation=0, ha='center', fontsize=10)
    
    ax1.legend(loc='best', frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc')

    plt.tight_layout()
    fig1.savefig('grafico_overhead_combinato.png')
    plt.close(fig1)

    # ==========================================
    # GRAFICO 2: MEMORIA DISPONIBILE
    # ==========================================
    fig2, ax2 = plt.subplots(figsize=(11, 6), dpi=300)
    
    ax2.plot(x_pos_memoria, df_memoria['Memoria_Disponibile_KB'], 
             marker='o', markersize=6, color=line_color, linestyle='-', linewidth=1.5, zorder=3, label='Memoria Disponibile')
    
    ax2.axhline(y=100, color='green', linestyle='--', linewidth=1.5, zorder=2, label='Memoria Base (100 KB)')
    
    ax2.set_title('Memoria Condivisa Disponibile al variare della configurazione\n(File: memoria.csv)', fontsize=14, pad=15)
    ax2.set_xlabel('Configurazione (Thread per Blocco -> Blocchi Max)', fontsize=12, labelpad=10)
    ax2.set_ylabel('Memoria Disponibile (KB)', fontsize=12)
    
    # Impostiamo il limite superiore dell'asse Y a 130
    ax2.set_ylim(bottom=0, top=110)
    ax2.yaxis.set_major_locator(MultipleLocator(10))
    
    ax2.set_xticks(x_pos_memoria)
    ax2.set_xticklabels(labels_x_memoria)
    
    ax2.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)

    # Etichette dei valori sopra i punti (Aggiunte anche per la memoria)
    for i, row in df_memoria.iterrows():
        ax2.annotate(f"{row['Memoria_Disponibile_KB']:.2f} KB",
                     (x_pos_memoria[i], row['Memoria_Disponibile_KB']),
                     textcoords="offset points",
                     xytext=(5, -17),
                     ha='center',
                     fontsize=9,
                     fontweight='bold',
                     color='#333333')

    plt.setp(ax2.get_yticklabels(), fontsize=11)
    plt.setp(ax2.get_xticklabels(), rotation=0, ha='center', fontsize=10)
    
    ax2.legend(frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc')

    plt.tight_layout()
    fig2.savefig('grafico_memoria_combinato.png')
    plt.close(fig2)

    print("Grafici riparati! Ora i dati si vedono tutti e le etichette sono su entrambi i grafici con Y fino a 130.")

if __name__ == "__main__":
    main()