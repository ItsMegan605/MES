import os
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# =========================================================================
# CONFIGURATION
# =========================================================================
input_dir = "csv"  
base_plots_dir = "plots"
os.makedirs(base_plots_dir, exist_ok=True)

csv_files = glob.glob(os.path.join(input_dir, "*.csv"))

if not csv_files:
    print(f"No CSV files found in '{input_dir}' directory.")
    exit()

# ==========================================
# GLOBAL STYLE SETTINGS
# ==========================================
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['axes.axisbelow'] = True
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['axes.facecolor'] = 'white'
plt.rcParams['axes.edgecolor'] = '#cccccc'
plt.rcParams['axes.linewidth'] = 1.2

line_color = '#4169e1'

for csv_file in csv_files:
    print(f"\n--------------------------------------------------")
    print(f"Processing file: {csv_file}")
    print(f"--------------------------------------------------")
    
    try:
        df = pd.read_csv(csv_file, sep=';', decimal=',')
    except Exception as e:
        print(f"Error reading {csv_file}: {e}")
        continue
        
    # --- NaN and inf handling ---
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    df.dropna(subset=['throughput'], inplace=True)
    
    # ---------------------------------------------------------
    # SCALE THROUGHPUT TO GB/s
    # ---------------------------------------------------------
    df['throughput'] = df['throughput'] / 1e9
    
    # ---------------------------------------------------------
    # FILTER: Keep ONLY rows with 'unevenstring'
    # ---------------------------------------------------------
    if 'stringa cercata' in df.columns:
        df = df[df['stringa cercata'] == 'unevenstring']
    
    if df.empty:
        print(f"Skipping {csv_file}: no valid data remaining for 'unevenstring'.")
        continue

    required_cols = ['stringa cercata', 'thread per blocco', 'throughput']
    if not all(col in df.columns for col in required_cols):
        print(f"Skipping {csv_file}: missing required columns.")
        continue
        
    csv_name = os.path.splitext(os.path.basename(csv_file))[0]
    output_dir = os.path.join(base_plots_dir, csv_name)
    os.makedirs(output_dir, exist_ok=True)
    
    t_min = df['throughput'].min()
    t_max = df['throughput'].max()
    ymin = 0 if t_min >= 0 else t_min * 1.1
    ymax = t_max * 1.15 if t_max > 0 else 1.0  
    
    unique_threads = sorted(df['thread per blocco'].unique())
    
    # =========================================================================
    # PLOT: Throughput vs Threads per Block
    # =========================================================================
    print(f"-> Generating plot for Threads per Block...")
    
    fig, ax = plt.subplots(figsize=(11, 6), dpi=300)
    
    sns.lineplot(
        data=df,
        x="thread per blocco",
        y="throughput",
        marker="o",
        markersize=6,
        color=line_color,
        linewidth=1.5,
        errorbar=('ci', 95),  
        err_style="bars",     
        err_kws={'capsize': 4},
        ax=ax,
        zorder=3
    )
    
    ax.set_title(f"Throughput by Thread Configuration\n(File: {csv_name} - Size: 4000MB)", fontsize=14, pad=15)
    ax.set_xlabel("Threads per Block", fontsize=12, labelpad=10)
    ax.set_ylabel("Average Throughput (GB/s, 95% CI)", fontsize=12)
    
    ax.set_ylim(bottom=ymin, top=ymax)
    ax.set_xticks(unique_threads)
    
    ax.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)

    # Calculate means to add labels above the points
    df_mean = df.groupby('thread per blocco')['throughput'].mean().reset_index()
    i = 0
    for _, row in df_mean.iterrows():
        ax.annotate(f"{row['throughput']:.2f}",
                     (row['thread per blocco'], row['throughput']),
                     textcoords="offset points",
                      xytext=(4, 10) if i != 0 else (4, -15),
                     ha='center',
                     fontsize=9,
                     fontweight='bold',
                     color='#333333')
        i = i + 1

    plt.setp(ax.get_yticklabels(), fontsize=11)
    plt.setp(ax.get_xticklabels(), rotation=0, ha='center', fontsize=10)
    
    filename_png = f"{csv_name}_throughput_vs_threads.png"
    filepath = os.path.join(output_dir, filename_png)
    
    plt.tight_layout()
    fig.savefig(filepath)
    plt.close(fig)

print(f"\nProcessing complete! Check the '{base_plots_dir}' directory for your plots.")
