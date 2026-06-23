import pandas as pd
import matplotlib.pyplot as plt

# Caricamento del dataset
df = pd.read_csv('StrideLocal16_results_unev.csv', sep=';')

# Pulizia e conversione della colonna throughput
df['throughput'] = df['throughput'].str.replace(',', '.').astype(float)

# Configurazione specificata: (thread, memoria)
configs = [
    (32, 72),
    (64, 72),
    (96, 84),
    (128, 87),
    (160, 90),
    (192, 92),
    (224, 93),
    (256, 93),
    (288, 95)
]

# Calcolo della media per ogni configurazione
results = []
for threads, mem in configs:
    mask = (df['thread per blocco'] == threads) & (df['limite shared mem'] == mem)
    mean_throughput = df[mask]['throughput'].mean()
    results.append({'thread per blocco': threads, 'limite shared mem': mem, 'throughput': mean_throughput})

df_plot = pd.DataFrame(results)

# Creazione del grafico
plt.figure(figsize=(10, 6))
plt.plot(df_plot['thread per blocco'], df_plot['throughput'], marker='o', linestyle='-', color='b')

# Personalizzazione
plt.title('Throughput vs Numero Thread (Configurazioni Specifiche)')
plt.xlabel('Numero Thread (Thread per Blocco)')
plt.ylabel('Throughput (Media)')
plt.grid(True)
plt.xticks(df_plot['thread per blocco']) # Mostra tutti i valori dei thread sull'asse X
plt.tight_layout()
plt.ylim(bottom=0)
plt.ylim(top=2.3e11)

# Salva/mostra grafico
plt.savefig("best_grafico.png", dpi=300, bbox_inches='tight')
plt.show()
