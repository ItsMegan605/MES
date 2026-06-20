import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
import os

def main():
    # Verifica l'esistenza dei file CSV
    if not os.path.exists('overhead.csv') or not os.path.exists('memoria.csv'):
        print("Errore: I file CSV non sono stati trovati.")
        return

    df_overhead = pd.read_csv('overhead.csv')
    df_memoria = pd.read_csv('memoria.csv')

    # ==========================================
    # IMPOSTAZIONI STILE GLOBALE
    # ==========================================
    plt.rcParams['font.family'] = 'sans-serif'
    plt.rcParams['axes.axisbelow'] = True      # METTE LA GRIGLIA SOTTO I DATI
    plt.rcParams['figure.facecolor'] = 'white'
    plt.rcParams['axes.facecolor'] = 'white'
    plt.rcParams['axes.edgecolor'] = '#cccccc' # Bordo del grafico
    plt.rcParams['axes.linewidth'] = 1.2

    line_color = '#4169e1'

    # ==========================================
    # GRAFICO 1: OVERHEAD
    # ==========================================
    fig1, ax1 = plt.subplots(figsize=(10, 6), dpi=300)
    
    ax1.plot(df_overhead['Threads'], df_overhead['Overhead_KB'], 
             marker='o', markersize=5, color=line_color, linestyle='-', linewidth=1.5, zorder=3, label='Overhead (KB)')
    
    ax1.axhline(y=100, color='red', linestyle='--', linewidth=1.5, zorder=2, label='Limite Massimo (100 KB)')
    
    ax1.set_title('Overhead al variare dei Thread\n(File: overhead.csv)', fontsize=14, pad=15)
    ax1.set_xlabel('Thread per Blocco', fontsize=12)
    ax1.set_ylabel('Overhead Medio (KB)', fontsize=12)
    
    ax1.set_ylim(bottom=0)
    
    # --- GESTIONE ASSI E GRIGLIA ---
    # Asse Y: Numeri e griglia rigorosamente ogni 10
    ax1.yaxis.set_major_locator(MultipleLocator(10))
    
    # Asse X: Mostra SOLO i numeri dei thread effettivamente testati
    ax1.set_xticks(df_overhead['Threads'])
    
    # Asse X: Imposta una griglia "invisibile" (minor ticks) a salti di 32 per tracciare le linee
    ax1.xaxis.set_minor_locator(MultipleLocator(32))
    
    # Disegna la griglia: principale (numeri Y e numeri X veri) + minore (salti da 32 su X)
    ax1.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)
    ax1.grid(which='minor', axis='x', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)

    plt.setp(ax1.get_xticklabels(), rotation=45, ha='right', fontsize=11)
    plt.setp(ax1.get_yticklabels(), fontsize=11)
    
    ax1.legend(frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc')

    plt.tight_layout()
    fig1.savefig('grafico_overhead.png')
    plt.close(fig1)

    # ==========================================
    # GRAFICO 2: MEMORIA DISPONIBILE
    # ==========================================
    fig2, ax2 = plt.subplots(figsize=(10, 6), dpi=300)
    
    ax2.plot(df_memoria['Threads'], df_memoria['Memoria_Disponibile_KB'], 
             marker='o', markersize=5, color=line_color, linestyle='-', linewidth=1.5, zorder=3, label='Memoria Disponibile')
    
    ax2.axhline(y=100, color='green', linestyle='--', linewidth=1.5, zorder=2, label='Memoria Base (100 KB)')
    
    ax2.set_title('Memoria Condivisa Disponibile al variare dei Thread\n(File: memoria.csv)', fontsize=14, pad=15)
    ax2.set_xlabel('Thread per Blocco', fontsize=12)
    ax2.set_ylabel('Memoria Disponibile (KB)', fontsize=12)
    
    ax2.set_ylim(bottom=0)
    
    # --- GESTIONE ASSI E GRIGLIA ---
    # Asse Y: Numeri e griglia ogni 10
    ax2.yaxis.set_major_locator(MultipleLocator(10))
    
    # Asse X: Solo i thread rilevanti
    ax2.set_xticks(df_memoria['Threads'])
    
    # Asse X: Griglia in background ogni 32
    ax2.xaxis.set_minor_locator(MultipleLocator(32))
    
    ax2.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)
    ax2.grid(which='minor', axis='x', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)

    plt.setp(ax2.get_xticklabels(), rotation=45, ha='right', fontsize=11)
    plt.setp(ax2.get_yticklabels(), fontsize=11)
    
    ax2.legend(frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc')

    plt.tight_layout()
    fig2.savefig('grafico_memoria.png')
    plt.close(fig2)

    print("Grafici creati con successo! Griglia Y a 10KB e asse X ottimizzato.")

if __name__ == "__main__":
    main()