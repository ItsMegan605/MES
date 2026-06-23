import matplotlib.pyplot as plt
import numpy as np
 
# 1. Inserimento dei dati (valori stimati dall'immagine)
categories = ['Stall Long Scoreboard', 'Stall Barrier']
 
# Valori per ciascuna categoria [Stall Long Scoreboard, Stall Barrier]
blue_data = [8.8, 8.9]      
green_data = [9.5, 5.8]     
purple_data = [8.7, 8.3]    
 
# 2. Configurazione della figura e dei colori di sfondo
fig, ax = plt.subplots(figsize=(12, 5))
sfondo_celeste = '#E0F7FA' # Celeste chiaro
colore_testo = '#000080'   # Blu scuro (Navy) per maggiore leggibilità
 
fig.patch.set_facecolor(sfondo_celeste)
ax.set_facecolor(sfondo_celeste)
 
# 3. Impostazione delle coordinate Y e dello spessore delle barre
y = np.arange(len(categories))
height = 0.25
 
# 4. Creazione delle barre (ordine dall'alto verso il basso per ogni gruppo)
ax.barh(y + height, blue_data, height, label='256 threads per block', color='#3399FF', edgecolor='white')
ax.barh(y, green_data, height, label='96 threads per block (our best configuration)', color='#4CAF50', edgecolor='white')
ax.barh(y - height, purple_data, height, label='192 threads per block', color='#A020F0', edgecolor='white')
 
# 5. Formattazione degli assi e dei testi (in blu e in inglese)
ax.set_yticks(y)
ax.set_yticklabels(categories, color=colore_testo, fontsize=12, fontweight='bold')
ax.tick_params(axis='x', colors=colore_testo, labelsize=11)
ax.tick_params(axis='y', colors=colore_testo)
ax.set_xlim(0, 10.0)
 
# 6. Griglia
ax.grid(True, axis='x', color='white', linestyle='-', linewidth=1.2)
ax.set_axisbelow(True) # Mette la griglia dietro le barre
 
# Coloriamo i bordi del grafico (spines) di blu
for spine in ax.spines.values():
    spine.set_color(colore_testo)
 
# 7. Aggiunta della legenda (tradotta in inglese e con testi blu)
ax.legend(
    loc='upper center', 
    bbox_to_anchor=(0.5, -0.15), 
    ncol=1, 
    facecolor=sfondo_celeste, 
    edgecolor=colore_testo, 
    labelcolor=colore_testo,
    fontsize=11
)
 
# Ottimizza gli spazi e mostra il grafico
plt.tight_layout()
plt.show()
