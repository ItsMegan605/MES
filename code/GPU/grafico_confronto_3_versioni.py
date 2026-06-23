import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# =========================================================================
# CONFIGURATION
# =========================================================================
output_dir = os.path.join("plots", "comparison")
os.makedirs(output_dir, exist_ok=True)

# Modificato 100kb in 99kb
file_base = "csv/StrideLocal16_results_99kb.csv"
file_code = "csv/StrideCode_results.csv"
file_old = "csv_old/StrideLocal16_results.csv"

# ==========================================
# GLOBAL STYLE SETTINGS
# ==========================================
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['axes.axisbelow'] = True
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['axes.facecolor'] = 'white'
plt.rcParams['axes.edgecolor'] = '#cccccc'
plt.rcParams['axes.linewidth'] = 1.2

color_base = '#4169e1'  # Blue
color_code = '#2ca02c'  # Green
color_old = '#d62728'   # Red (Modificato da orange)

def load_and_clean(filepath, apply_best_config=False):
    if not os.path.exists(filepath):
        print(f"File non trovato: {filepath}")
        return pd.DataFrame()
        
    try:
        df = pd.read_csv(filepath, sep=';', decimal=',')
    except Exception as e:
        print(f"Errore nella lettura di {filepath}: {e}")
        return pd.DataFrame()

    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    
    if df['throughput'].dtype == object:
        df['throughput'] = df['throughput'].str.replace(',', '.').astype(float)
        
    df.dropna(subset=['throughput'], inplace=True)
    df['throughput'] = df['throughput'] / 1e9
    
    if 'stringa cercata' in df.columns:
        df = df[df['stringa cercata'] == 'unevenstring']
        
    if apply_best_config:
        configs = [(32, 72), (64, 72), (96, 84), (128, 87), (160, 90), 
                   (192, 92), (224, 93), (256, 93), (288, 95)]
        
        mask = pd.Series(False, index=df.index)
        for t, m in configs:
            mask = mask | ((df['thread per blocco'] == t) & (df['limite shared mem'] == m))
        df = df[mask]
        
    return df

def generate_multi_plot(datasets, title, filename, ymax_fixed=None):
    valid_datasets = [ds for ds in datasets if not ds['df'].empty]
    if not valid_datasets:
        print(f"Dati insufficienti per generare {filename}. Salto il grafico.")
        return

    fig, ax = plt.subplots(figsize=(11, 6), dpi=300)
    
    t_min = float('inf')
    t_max = float('-inf')
    unique_threads = set()

    for ds in valid_datasets:
        df = ds['df']
        
        t_min = min(t_min, df['throughput'].min())
        t_max = max(t_max, df['throughput'].max())
        unique_threads.update(df['thread per blocco'])

        sns.lineplot(
            data=df, x="thread per blocco", y="throughput",
            marker=ds.get('marker', 'o'), markersize=6, 
            color=ds['color'], linewidth=1.5,
            linestyle=ds.get('linestyle', '-'),
            errorbar=('ci', 95), err_style="bars", err_kws={'capsize': 4},
            ax=ax, zorder=3, label=ds['label']
        )

        df_mean = df.groupby('thread per blocco')['throughput'].mean().reset_index()
        df_mean = df_mean.sort_values('thread per blocco').reset_index(drop=True)
        
        # Recupera l'offset personalizzato per il primo punto (default -15)
        offset_y_first = ds.get('offset_y_first', -15)
        
        for i, row in df_mean.iterrows():
            if i == 0:
                xy_offset = (1, offset_y_first)
            else:
                xy_offset = (1, 10)

            ax.annotate(f"{row['throughput']:.2f}",
                         (row['thread per blocco'], row['throughput']),
                         textcoords="offset points",
                         xytext=xy_offset,
                         ha='center',
                         fontsize=9,
                         fontweight='bold',
                         color='black')

    ax.set_title(title, fontsize=14, pad=15)
    ax.set_xlabel("Threads per Block", fontsize=12, labelpad=10)
    ax.set_ylabel("Average Throughput (GB/s, 95% CI)", fontsize=12)
    
    if t_min != float('inf'):
        if ymax_fixed is not None:
            ax.set_ylim(bottom=0 if t_min >= 0 else t_min * 1.1, top=ymax_fixed) #CULO
        else:
            ax.set_ylim(bottom=0 if t_min >= 0 else t_min * 1.1, top=t_max * 1.15 if t_max > 0 else 1.0)
            
        ax.set_xticks(sorted(list(unique_threads)))
    
    ax.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)
    plt.setp(ax.get_yticklabels(), fontsize=11)
    plt.setp(ax.get_xticklabels(), rotation=0, ha='center', fontsize=10)
    
    ax.legend(frameon=True, facecolor='white', framealpha=1, edgecolor='#cccccc', loc='upper left')
    
    filepath = os.path.join(output_dir, filename)
    plt.tight_layout()
    fig.savefig(filepath)
    plt.close(fig)
    print(f"Grafico salvato: {filepath}")

# =========================================================================
# ESECUZIONE
# =========================================================================

print("Caricamento dei dataset in corso...")
df_base = load_and_clean(file_base)
df_code = load_and_clean(file_code)
df_old  = load_and_clean(file_old, apply_best_config=True)

# Grafico 1
print("\n-> Generazione Grafico 1: StrideLocal16 vs StrideCode")
generate_multi_plot(
    datasets=[
        {'df': df_base, 'label': 'StrideLocal16 (99KB)', 'color': color_base, 'marker': 'o', 'linestyle': '-'},
        {'df': df_code, 'label': 'StrideCode', 'color': color_code, 'marker': 's', 'linestyle': '-'}
    ],
    title="Throughput Comparison: StrideLocal16 vs StrideCode",
    filename="comparison_local16_vs_code.png"
)

# Grafico 2 (Limite Y a 250)
print("\n-> Generazione Grafico 2: StrideLocal16_99kb vs StrideLocal16_best")
generate_multi_plot(
    datasets=[
        {'df': df_base, 'label': 'StrideLocal16 (99KB Limit)', 'color': color_base, 'marker': 'o', 'linestyle': '-'},
        # Label offset di 5 punti più in basso (da -15 a -20)
        {'df': df_old, 'label': 'StrideLocal16 (Best Configs)', 'color': color_old, 'marker': '^', 'linestyle': '-', 'offset_y_first': 17}
    ],
    title="Throughput Comparison: New Memory Limit vs Best Configs",
    filename="comparison_local16_new_vs_Best.png",
    ymax_fixed=250
)

# Grafico 3 (Tutti e 3, Limite Y a 250)
print("\n-> Generazione Grafico 3: StrideLocal16 vs StrideCode vs Best")
generate_multi_plot(
    datasets=[
        {'df': df_base, 'label': 'StrideLocal16 (99KB Limit)', 'color': color_base, 'marker': 'o', 'linestyle': '-'},
        {'df': df_code, 'label': 'StrideCode', 'color': color_code, 'marker': 's', 'linestyle': '--'},
        # Label offset di 5 punti più in basso (da -15 a -20)
        {'df': df_old, 'label': 'StrideLocal16 (Best Configs)', 'color': color_old, 'marker': '^', 'linestyle': '-', 'offset_y_first': 17}
    ],
    title="Global Throughput Comparison: All Configurations",
    filename="comparison_all.png",
    ymax_fixed=260
)

print("\nProcesso completato.")
