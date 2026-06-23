import pandas as pd
import matplotlib.pyplot as plt
import textwrap

data = {
    'StrideCode': [34.15],
    'StrideCode (fetch only)': [48.19],
    'StrideTail': [81.15],
    'StrideTail (fetch only)': [301.59],
    'StrideFast': [105.64],
    'StrideFast (fetch only)': [347.39]
}
df = pd.DataFrame(data)
all_cols = list(df.columns)

display_order = [
    'StrideCode', 
    'StrideTail', 
    'StrideFast', 'StrideCode (fetch only)','StrideTail (fetch only)','StrideFast (fetch only)'
]

# Nuova palette: coppie cromatiche scuro/chiaro coerenti e visivamente distinte
color_map = {
    'StrideCode': '#2b5c8f',              # Blu scuro
    'StrideCode (fetch only)': '#74a9cf', # Blu chiaro
    'StrideTail': '#E95A60',          
    'StrideTail (fetch only)': '#F39B7F',
    'StrideFast': '#5bc4bc',     
    'StrideFast (fetch only)': '#9dd6d6' 
}

plot_configs = [
    ("Plot 1 (Prime 2 colonne)", all_cols[:2]),
    ("Plot 2 (Prime 4 colonne)", all_cols[:4]),
    ("Plot 3 (Prime 6 colonne)", all_cols[:6]),
    ("Plot 4 Extra (Ultime 4 colonne)", all_cols[-4:])
]

figs = []

for title, subset_cols in plot_configs:
    ordered_cols = [c for c in display_order if c in subset_cols]
    
    y_vals = [df[c].iloc[0] for c in ordered_cols]
    colors = [color_map[c] for c in ordered_cols]
    
    x_labels = ['\n'.join(textwrap.wrap(c, width=15)) for c in ordered_cols]

    fig, ax = plt.subplots(figsize=(10, 6))
    fig.canvas.manager.set_window_title(title)
    
    # zorder=3 posiziona le barre in primo piano rispetto alla griglia
    bars = ax.bar(x_labels, y_vals, color=colors, zorder=3)
    
    ax.tick_params(axis='y', labelsize=14)
    ax.tick_params(axis='x', labelsize=12)
    ax.set_ylim(0, 400)#445)
    ax.set_ylabel('Bandwidth (GB/s)', fontsize=18, labelpad=20)
    ax.set_title('Bandwidth Comparison', fontsize=15, pad=10)
    
    # Attivazione griglia orizzontale (zorder=0 la posiziona in background)
    ax.grid(axis='y', linestyle='-', alpha=0.6, zorder=0)
    
    # Adattamento stile linea Max Bandwidth
    ax.axhline(y=384, color='#B90E0A', linestyle='--', linewidth=2, label='Max Bandwidth (384 GB/s)', zorder=4)
    
    for bar in bars:
        yval = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2, yval + 5, f'{yval}', ha='center', va='bottom', fontsize=11, fontweight='bold')
    
    #ax.legend(loc='upper left', fontsize=13)
    plt.tight_layout()
    figs.append(fig)

plt.show()
