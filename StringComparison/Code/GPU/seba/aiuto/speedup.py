import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# ==========================================
# IMPOSTAZIONI STILE 
# ==========================================
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['axes.axisbelow'] = True
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['axes.facecolor'] = 'white'
plt.rcParams['axes.edgecolor'] = '#cccccc'
plt.rcParams['axes.linewidth'] = 1.2

def main():
    # 1. Lettura dati
    df = pd.read_csv('StrideLocal16_results_speedup.csv', sep=';')

    # 2. Pulizia colonna throughput
    df['throughput'] = df['throughput'].astype(str).str.replace(',', '.')
    df['throughput'] = pd.to_numeric(df['throughput'], errors='coerce')
    df = df.replace([np.inf, -np.inf], np.nan).dropna(subset=['throughput'])

    # 3. Calcolo numero di warp (X axis)
    # 26 SM * 3 warp/blocco * numero di blocchi per SM
    warp_per_blocco = 26 * 3
    df['warps'] = df['blocchi per SM'] * warp_per_blocco

    # 4. Calcolo baseline e speedup per ogni dimensione file
    baseline = df[df['blocchi per SM'] == 1].groupby('dimensione file')['throughput'].mean().reset_index()
    baseline = baseline.rename(columns={'throughput': 'baseline_throughput'})

    df = df.merge(baseline, on='dimensione file')
    df['speedup'] = df['throughput'] / df['baseline_throughput']

    # 5. Creazione grafico
    fig, ax = plt.subplots(figsize=(12, 6))

    # Plot principale dello speedup misurato
    sns.lineplot(
        data=df,
        x='warps',
        y='speedup',
        marker='o',
        markersize=8,
        linewidth=2.5,
        errorbar=('ci', 95),  
        err_style="bars",     
        err_kws={'capsize': 5},
        ax=ax,
        zorder=3,
        color='#2ca02c', 
        label='StrideFast'
    )

    # 6. Aggiunta della bisettrice tratteggiata semitrasparente (Speedup Ideale)
    x_min, x_max = df['warps'].min(), df['warps'].max()
    # Lo speedup ideale in x_min (1 blocco per SM) è 1. In x_max è x_max / warp_per_blocco.
    y_min, y_max = 1, x_max / warp_per_blocco
    
    ax.plot([x_min, x_max], [y_min, y_max], 
            linestyle='--', 
            linewidth=2, 
            color='gray', 
            alpha=0.4, 
            zorder=2, 
            label='Ideal Speedup')

    # 7. Annotazioni dei valori medi
    df_mean = df.groupby('warps')['speedup'].mean().reset_index()

    for idx, row in df_mean.iterrows():
        y_offset = 12
            
        ax.annotate(f"{row['speedup']:.2f}",
                     (row['warps'], row['speedup']),
                     textcoords="offset points",
                     xytext=(0, y_offset),
                     ha='center',
                     fontsize=10,
                     fontweight='bold')

    # 8. Formattazione assi
    ax.set_xlabel('Warp Number', fontsize=14)
    ax.set_ylabel('Speedup', fontsize=14)
    ax.set_title('Speedup', fontsize=16, fontweight='bold')
    ax.tick_params(axis='both', which='major', labelsize=12)

    # Mostra tutti i tick effettivi sull'asse x
    ax.set_xticks(sorted(df['warps'].unique()))
    ax.grid(True, linestyle='--', alpha=0.7, zorder=0)

    ax.legend(fontsize=12, loc='best')

    # 9. Salvataggio
    plt.tight_layout()
    path_file = "speedup_vs_warps.svg"
    fig.savefig(path_file, format='svg')
    plt.close(fig)
    print(f"-> Grafico salvato come '{path_file}'.")

if __name__ == "__main__":
    main()
