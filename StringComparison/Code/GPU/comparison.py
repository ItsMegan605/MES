import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# 1. Definiamo i file da leggere usando il nuovo file per Stride 16
stride = {
    'Stride 16': 'StrideLocal16_7000.csv', # <-- FILE AGGIORNATO
    'Stride Int': 'StrideLocalInt_results.csv',
    'Stride Char': 'StrideLocalChar_results.csv'#,
    #'Stride Long': 'StrideLocalLong_results.csv'
}

kmp = {

    'KMP16' : 'KMP16_results.csv',
    'KMPInt' : 'KMPInt_results.csv',
    'KMP' : 'KMP_results.csv'#,
    #'KMPLong' : 'KMPLong_results.csv'

}

files = stride

dfs = []

# 2. Iteriamo sui file, leggiamo, filtriamo e assegniamo l'etichetta
for name, file_path in files.items():
    try:
        df = pd.read_csv(file_path, sep=';')
        
        # FILTRO: solo esecuzioni con 7000 MB e stringa 'abracadabra'
        df_filtered = df[(df['dimensione file'] == 7000) & (df['stringa cercata'] == 'abracadabra')].copy()
        
        # Aggiungiamo una colonna per distinguere l'implementazione
        df_filtered['Implementazione'] = name
        dfs.append(df_filtered)
        
    except FileNotFoundError:
        print(f"Attenzione: il file {file_path} non è stato trovato.")

# 3. Combiniamo tutti i dati filtrati in un unico DataFrame
combined_df = pd.concat(dfs, ignore_index=True)

# 4. Pulizia del formato numerico: convertiamo il throughput testuale in float
combined_df['throughput'] = combined_df['throughput'].astype(str).str.replace(',', '.').astype(float)

# 5. Impostazioni grafiche (stile di Seaborn)
plt.figure(figsize=(12, 8))
sns.set_theme(style="whitegrid", context="talk")

# 6. Creazione del Lineplot unificato
ax = sns.lineplot(
    data=combined_df,
    x='thread per blocco',
    y='throughput',
    hue='Implementazione',
    marker='o',
    err_style='bars',       
    errorbar=('ci', 95),    
    err_kws={'capsize': 5, 'elinewidth': 2}
)

# 7. Personalizzazione di Titolo, Assi e Legenda
plt.title("Confronto Throughput (File: 7000 MB, Stringa: 'abracadabra')", fontsize=18)
plt.xlabel('Thread per Blocco', fontsize=16)
plt.ylabel('Throughput Medio (GB/s stimato, con CI 95%)', fontsize=16)

# Impostiamo i tick esatti sull'asse X
unique_threads = sorted(combined_df['thread per blocco'].unique())
plt.xticks(unique_threads, rotation=45)

# Assicuriamo che l'asse Y parta da zero
plt.ylim(0, combined_df['throughput'].max() * 1.1)

# Posizioniamo la legenda all'esterno del grafico
plt.legend(title='Implementazione', bbox_to_anchor=(1.05, 1), loc='upper left')

# 8. Salvataggio del grafico
plt.tight_layout()
plt.savefig('confronto_throughput_aggiornato.png', dpi=300)
plt.show()