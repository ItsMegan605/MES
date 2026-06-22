import matplotlib.pyplot as plt
import numpy as np
 
# --- Dati del grafico ---
labels = [
    "Others",
    "Stall Not Selected",
    "Stall Branch Resolving",
    "Stall Short Scoreboard",
    "Stall Wait",
    "Stall Barrier",
    "Stall Long Scoreboard"
]
 
values = [
    0.30,
    0.69,
    0.76,
    2.41,
    3.29,
    5.77,
    9.63
]
 
# --- Definizione dei colori ---
maroon_color = '#7A1A1A'   # Per le prime due barre in alto
blue_gray_color = '#406080' # Per le altre cinque barre in basso
grid_color = '#E0E0E0'      # Per la griglia verticale
text_color = '#406080'      # Per i numeri dell'asse X e il titolo
 
bar_colors = [blue_gray_color] * 5 + [maroon_color] * 2
 
# --- Creazione del grafico ---
# Impostiamo lo sfondo esterno dell'intera figura a bianco
fig, ax = plt.subplots(figsize=(10, 5), facecolor='white')
 
# Impostiamo lo sfondo interno del grafico a bianco
ax.set_facecolor('white')
 
# Creiamo le barre orizzontali. Aggiungiamo zorder=3 per forzarle in primo piano
bars = ax.barh(labels, values, color=bar_colors, height=0.6, zorder=3)
 
# --- Formattazione dell'asse Y (Etichette) ---
ax.tick_params(axis='y', length=0)
 
for label_obj in ax.get_yticklabels():
    text = label_obj.get_text()
    if text == "Stall Long Scoreboard" or text == "Stall Barrier":
        label_obj.set_color(maroon_color)
    else:
        label_obj.set_color(blue_gray_color)
    label_obj.set_fontname('sans-serif')
    label_obj.set_fontweight('bold')
    label_obj.set_fontsize(11)
 
# --- Formattazione dell'asse X (Numeri e Titolo) ---
ax.set_xlim(0, 10.5)
ax.set_xticks([0, 2, 4, 6, 8, 10])
ax.tick_params(axis='x', colors=text_color, labelsize=10, pad=10)
ax.set_xlabel('Cycles per instruction', color=text_color, fontsize=11, labelpad=15)
 
# --- Griglia e Bordi ---
# Aggiungiamo la griglia verticale. Impostiamo zorder=1 per forzarla sullo sfondo
ax.grid(axis='x', color=grid_color, linestyle='-', linewidth=0.7, zorder=1)
 
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_color(grid_color)
ax.spines['bottom'].set_color(grid_color)
 
# --- Aggiunta dei valori numerici a destra delle barre ---
# Usiamo zorder=4 per garantire che i numeri siano visibili sopra le barre, anche se non si sovrappongono
for bar, value, color in zip(bars, values, bar_colors):
    ax.text(
        value + 0.1,
        bar.get_y() + bar.get_height() / 2,
        f'{value:.2f}',
        va='center',
        ha='left',
        color=color,
        fontweight='bold',
        fontsize=11,
        zorder=4
    )
 
plt.tight_layout()
 
# Mostra il grafico
plt.show()
