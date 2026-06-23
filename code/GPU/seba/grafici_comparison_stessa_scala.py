import os
import sys
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# ==========================================
# GLOBAL STYLE SETTINGS
# ==========================================
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['axes.axisbelow'] = True
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['axes.facecolor'] = 'white'
plt.rcParams['axes.edgecolor'] = '#cccccc'
plt.rcParams['axes.linewidth'] = 1.2

# ==========================================
# COLOR MAPPING
# ==========================================
FIXED_COLORS = {
    'StrideCode': '#1f77b4',        # Blu
    'StrideTail': '#2ca02c',     # Verde
    'StrideFast': '#d62728'  # Rosso
}

def main():
    csv_files = sorted(glob.glob("*.csv"))
    
    if not csv_files:
        print("No CSV files found in the current directory.")
        sys.exit()

    fallback_colors = sns.color_palette("Set2") 
    loaded_data = []
    
    step = 0
    while True:
        step += 1
        print("\nAvailable CSV files:")
        for i, file_name in enumerate(csv_files, start=1):
            print(f"[{i}] {file_name}")
        print("[0] Exit")
        
        choice = input("\nSelect a CSV file to add to the plot (0-{}): ".format(len(csv_files))).strip()
        
        if choice == '0' or choice.lower() == 'q':
            break
            
        if not choice.isdigit() or int(choice) < 1 or int(choice) > len(csv_files):
            print("Invalid selection. Please try again.")
            continue
            
        selected_file = csv_files[int(choice) - 1]
        base_name = os.path.basename(selected_file)
        print(f"Processing: {selected_file}")
        
        try:
            df = pd.read_csv(selected_file, sep=';', decimal=',')
        except Exception as e:
            print(f"Error reading {selected_file}: {e}")
            continue
            
        # Pulizia dati
        df.replace([np.inf, -np.inf], np.nan, inplace=True)
        df.dropna(subset=['throughput'], inplace=True)
        
        df['throughput'] = df['throughput'] / 1e9
        
        if 'stringa cercata' in df.columns:
            df = df[df['stringa cercata'] == 'unevenstring']
            
        if df.empty:
            print(f"Skipping {selected_file}: no valid data remaining for 'unevenstring'.")
            continue

        required_cols = ['thread per blocco', 'throughput']
        if not all(col in df.columns for col in required_cols):
            print(f"Skipping {selected_file}: missing required columns.")
            continue

        nome = base_name.split('_')[0]
        
        if nome in FIXED_COLORS:
            curve_color = FIXED_COLORS[nome]
        else:
            fallback_index = len([d for d in loaded_data if d['name'] not in FIXED_COLORS])
            curve_color = fallback_colors[fallback_index % len(fallback_colors)]
        
        # Salvataggio dati in memoria
        loaded_data.append({
            'df': df,
            'name': nome,
            'color': curve_color,
            'is_best': 'best' in base_name.lower() # Aggiunto flag mancante per determinare is_best
        })
        
        # ==========================================
        # PLOTTING
        # ==========================================
        fig, ax = plt.subplots(figsize=(12, 7), dpi=300)
        
        base_title_name = loaded_data[0]['name']
        ax.set_title(f"{base_title_name} Throughput", fontsize=18, pad=20, fontweight='bold')
        ax.set_xlabel("Threads per Block", fontsize=16, labelpad=12)
        ax.set_ylabel("Average Throughput (GB/s)", fontsize=16, labelpad=12)
        ax.grid(which='major', color='#e0e0e0', linestyle='-', linewidth=1, zorder=1)
        ax.set_ylim(bottom=0, top=220)
        
        for data_item in loaded_data:
            curr_df = data_item['df']
            
            sns.lineplot(
                data=curr_df,
                x="thread per blocco",
                y="throughput",
                marker="o",
                markersize=8,
                color=data_item['color'],
                linewidth=2,
                errorbar=('ci', 95),  
                err_style="bars",     
                err_kws={'capsize': 5},
                ax=ax,
                zorder=3,
                label=data_item['name']
            )
            
            df_mean = curr_df.groupby('thread per blocco')['throughput'].mean().reset_index()
            
            for idx, row in df_mean.iterrows():
                y_offset = 12
                
                # Regole posizionamento etichette
                if idx == 0:
                    y_offset = -16
                    
                ax.annotate(f"{row['throughput']:.2f}",
                             (row['thread per blocco'], row['throughput']),
                             textcoords="offset points",
                             xytext=(0, y_offset),
                             ha='center',
                             fontsize=10,
                             fontweight='bold')

        ax.tick_params(axis='both', which='major', labelsize=14)
        
        all_xticks = set()
        for d in loaded_data:
            all_xticks.update(d['df']['thread per blocco'].unique())
        ax.set_xticks(sorted(list(all_xticks)))
        
        ax.legend(fontsize=12, loc='best')
        
        plt.tight_layout()
        path_file = f"{base_title_name}_throughput_{step}.svg"
        fig.savefig(path_file, format='svg')
        plt.close(fig)
        print(f"-> Curve added and plot saved to '{path_file}'.")

if __name__ == "__main__":
    main()
