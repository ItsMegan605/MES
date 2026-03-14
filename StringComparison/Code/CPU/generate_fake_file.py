import os
from faker import Faker

def genera_file_mockup():
    try:
        dim_mb = float(input("Inserisci la dimensione del file in MB (es. 50, 100): "))
    except ValueError:
        print("Errore: inserisci un numero valido.")
        return

    target_bytes = int(dim_mb * 1024 * 1024)
    nome_file = "mockup_testo.txt"
    
    fake = Faker('it_IT')
    bytes_scritti = 0
    chunk_size = 50 
    
    print(f"\nGenerazione di '{nome_file}' in corso...")
    
    with open(nome_file, 'w', encoding='utf-8') as f:
        while bytes_scritti < target_bytes:
            # Genera testo fittizio
            paragrafi = fake.paragraphs(nb=chunk_size)
            blocco_testo = "\n".join(paragrafi) + "\n"
            
            # Scrive sul file
            f.write(blocco_testo)
            
            # Calcola i byte reali (UTF-8) e aggiorna il contatore
            bytes_scritti += len(blocco_testo.encode('utf-8'))
            
            # Stampa i byte scritti sovrascrivendo la riga a terminale
            print(f"\rByte scritti: {bytes_scritti} / {target_bytes}", end="")

    print(f"\n\nCompletato. File '{nome_file}' pronto all'uso.")

if __name__ == "__main__":
    genera_file_mockup()
