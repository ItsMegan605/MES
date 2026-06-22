import matplotlib.pyplot as plt
import numpy as np
 
# Categorie sull'asse Y (ordinate dal basso verso l'alto per il grafico orizzontale)
categories = ['Stall Barrier', 'Stall Long Scoreboard']
 
# Dati per i due vettori di test
stride_code_vals = [5.77, 9.63]  # Barre Rosse
stride_16_vals = [0.70, 1.23]    # Barre Blu
 
# Definizione dei colori esatti
red_color = '#7A1315'   # Stride Code
blue_color = '#1D4468'  # Stride 16
 
# Impostazione delle posizioni delle barre sull'asse Y
y = np.arange(len(categories))
height = 0.35  # Spessore di ciascuna barra
 
# Creazione della figura
fig, ax = plt.subplots(figsize=(12, 5), facecolor='#FFFFFF')
ax.set_facecolor('white')
 
# Creazione delle barre raggruppate (una sopra/sotto l'altra per ogni categoria)
# 'Stride Code' (Rosso) viene posizionato leggermente più in alto (+ height/2)
bars_red = ax.barh(y + height/2, stride_code_vals, height=height, color=red_color, label='StrideCode', zorder=3)
 
# 'Stride 16' (Blu) viene posizionato immediatamente sotto (- height/2)
bars_blue = ax.barh(y - height/2, stride_16_vals, height=height, color=blue_color, label='StrideTail', zorder=3)
 
# Griglia stile Excel: attiva sia su X che su Y, continua e a maglia fitta
ax.grid(visible=True, which='major', axis='x', color='#D9D9D9', linestyle='-', linewidth=0.8, zorder=0)
 
# Configurazione dell'asse X (passo di 1 unità per massima precisione di lettura)
ax.set_xlim(0, 10.5)
ax.set_xticks(np.arange(0, 11, 1))
ax.tick_params(axis='x', colors='#333333', length=0, labelsize=13, pad=8)
ax.set_xlabel('Cycles per instruction', color='#333333', fontstyle='italic', fontsize=14, labelpad=10)
 
# Configurazione dell'asse Y
ax.set_yticks(y)
ax.set_yticklabels(categories, fontsize=13, fontweight='bold', color='#23395d')
ax.tick_params(axis='y', length=0, pad=15)
 
# Rimozione dei bordi esterni per alleggerire il design, mantenendo solo le linee di griglia interne
for spine in ax.spines.values():
    spine.set_visible(False)
 
# Aggiunta dei valori numerici a destra di ogni singola barra
for bar in bars_red:
    width = bar.get_width()
    ax.text(width + 0.12, bar.get_y() + bar.get_height() / 2, f'{width:.2f}',
            ha='left', va='center', color=red_color, fontweight='bold', fontsize=11, zorder=4)
 
for bar in bars_blue:
    width = bar.get_width()
    ax.text(width + 0.12, bar.get_y() + bar.get_height() / 2, f'{width:.2f}',
            ha='left', va='center', color=blue_color, fontweight='bold', fontsize=11, zorder=4)
 
# Creazione della legenda personalizzata in alto a destra
ax.legend(loc='lower right', frameon=True, facecolor='white', edgecolor='#D9D9D9', fontsize=12, shadow=False)
 
# Ottimizzazione dei margini
plt.tight_layout()
 
# Mostra il grafico
plt.show()
