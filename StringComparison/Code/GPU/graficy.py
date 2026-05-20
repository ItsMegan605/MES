import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Imposta uno stile pulito
sns.set_theme(style="whitegrid")

print("Lettura del dataset in corso...")

try:
    df = pd.read_csv('benchmark_results.csv', sep=';', decimal=',')
except FileNotFoundError:
    print("Errore: Impossibile trovare 'benchmark_results.csv'.")
    exit()

# Calcolo della media sulle ripetizioni
df_mean = df.groupby(['stringa cercata', 'thread per blocco', 'dimensione file'])['throughput'].mean().reset_index()

print("Generazione dei grafici...")

# ==========================================
# GRAFICO 1: FISSIAMO LA STRINGA
# ==========================================
# Per ogni stringa vediamo come si comportano i thread, al variare della dimensione file
g1 = sns.relplot(
    data=df_mean,
    x="thread per blocco",
    y="throughput",
    hue="dimensione file", 
    col="stringa cercata", 
    kind="line",
    marker="o",
    palette="viridis",
    height=5,
    aspect=1.2
)
g1.set_axis_labels("Thread per Blocco", "Throughput Medio")
g1.set_titles("Stringa: '{col_name}'")
g1.fig.suptitle("Analisi per Stringa (Linee = Dimensione File MB)", y=1.05, fontweight='bold')

for ax in g1.axes.flat:
    ax.set_xticks(sorted(df_mean['thread per blocco'].unique()))
    ax.tick_params(axis='x', rotation=45)

plt.savefig("grafico_per_stringa.png", dpi=300, bbox_inches='tight')
plt.close()
print("1. Salvato 'grafico_per_stringa.png'")


# ==========================================
# GRAFICO 2: FISSIAMO LA DIMENSIONE DEL FILE (ORA A LINEE)
# ==========================================
# Per ogni dimensione file vediamo come si comportano i thread, al variare della stringa
g2 = sns.relplot(
    data=df_mean,
    x="thread per blocco",
    y="throughput",
    hue="stringa cercata", 
    col="dimensione file", 
    kind="line",
    marker="o",
    palette="tab10",
    height=5,
    aspect=1.2
)
g2.set_axis_labels("Thread per Blocco", "Throughput Medio")
g2.set_titles("Dimensione File: {col_name} MB")
g2.fig.suptitle("Analisi per Dimensione File (Linee = Stringa)", y=1.05, fontweight='bold')

for ax in g2.axes.flat:
    ax.set_xticks(sorted(df_mean['thread per blocco'].unique()))
    ax.tick_params(axis='x', rotation=45)

plt.savefig("grafico_per_dimensione_linee.png", dpi=300, bbox_inches='tight')
plt.close()
print("2. Salvato 'grafico_per_dimensione_linee.png'")

print("Fatto! File snellito e grafici a linee pronti.")