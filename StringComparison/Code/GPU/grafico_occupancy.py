import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
import os
import numpy as np

def main():
    # Verifica l'esistenza del file CSV
    if not os.path.exists('overhead.csv'):
        print("Errore: Il file 'overhead.csv' non è stato trovato.")
        return

    # Leggiamo i dati
    df = pd.read_csv('overhead.csv')

    # Filtriamo i thread per non superare il limite architetturale di 1024
    df = df[df['Threads'] <= 1024].copy()

    # Ordiniamo per Threads
    df = df.sort_values(by='Threads').reset_index(drop=True)

    # ==========================================
    # IMPOSTAZIONI STILE GLOBALE
    # ==========================================
    plt.rcParams['font.family'] = 'sans-serif'
    plt.rcParams['axes.axisbelow'] = True
    plt.rcParams['figure.facecolor'] = 'white'
    plt.rcParams['axes.facecolor'] = 'white'
    plt.rcParams['axes.edgecolor'] = '#cccccc'
    plt.rcParams['axes.linewidth'] = 1.2

    line_color = '#8e44ad'

    # Array per rendere i punti equidistanti
    x_pos = np.arange(len(df))

    # ==========================================
    # CREAZIONE GRAFICO: THREAD VS BLOCCHI
    # ==========================================
    fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
    
    # Linea a 24 per l'Architectural Limit
    ax.axhline(y=24, color='red', linestyle='--', linewidth=1.5, zorder=2, label='Architectural Limit (24)')

    ax.plot(x_pos, df['Numero_Blocchi'], 
             marker='o', markersize=6, color=line_color, linestyle='-', linewidth=2, zorder=3, label='Blocchi Attivi (Occupancy)')
    
    ax.set_title('Relazione tra Thread per Blocco e Numero di Blocchi Max\nLimite Architetturale: 1024 Thread', fontsize=14, pad=15)
    ax.set_xlabel('Numero di Thread per Blocco', fontsize=12, labelpad=10)
    ax.set_ylabel('Numero di Blocchi Max', fontsize=12)
    
    # --- LIMITI ASSI Y ---
    # Asse Y: da 0 a 26 come richiesto
    ax.set_ylim(bottom=0, top=26.5)
    ax.yaxis.set_major_locator(MultipleLocator(2))
    ax.yaxis.set_minor_locator(MultipleLocator(1))
    
    # --- LIMITI E FORMATTAZIONE ASSE X ---
    # Mostriamo solo i thread importanti ai rispettivi punti equidistanti
    ax.set_xticks(x_pos)
    ax.set_xticklabels([str(int(t)) for t in df['Threads']])
    
    # Lasciamo un margine visivo all'inizio e alla fine per non far "toccare" i bordi
    ax.set_xlim(left=-0.5, right=len(df) - 0.5)
    
    # --- GRIGLIA ---
    ax.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)
    ax.grid(which='minor', axis='y', color='#f0f0f0', linestyle='--', linewidth=0.5, zorder=1)

    # --- ETICHETTE VALORI SUI PUNTI ---
    for i, row in df.iterrows():
        ax.annotate(f"{int(row['Numero_Blocchi'])}",
                     (x_pos[i], row['Numero_Blocchi']),
                     textcoords="offset points",
                     xytext=(0, 10),
                     ha='center',
                     fontsize=10,
                     fontweight='bold',
                     color='#333333')

    # Aggiungiamo un testo esplicito sopra la riga rossa per renderlo ancora più chiaro
    ax.text(x_pos[-1], 24.3, 'Architectural Limit', color='red', ha='right', va='bottom', fontsize=10, fontweight='bold', zorder=4)

    # Formattazione
    plt.setp(ax.get_yticklabels(), fontsize=11)
    plt.setp(ax.get_xticklabels(), rotation=0, ha='center', fontsize=11)
    
    ax.legend(loc='upper right', frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc')

    plt.tight_layout()
    fig.savefig('grafico_occupancy_thread_blocchi.png')
    plt.close(fig)

    print("Grafico dell'occupancy con Architectural Limit a 24 generato con successo!")

if __name__ == "__main__":
    main()