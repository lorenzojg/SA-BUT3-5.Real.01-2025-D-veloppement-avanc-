import json
import csv
import os

def main():
    # Définition des chemins
    base_dir = os.path.dirname(os.path.abspath(__file__))
    input_file = os.path.join(base_dir, 'resultats_voyage_complets.jsonl')
    output_file = os.path.join(base_dir, 'city_data.csv')

    print(f"Lecture de {input_file}...")

    data = []
    all_keys = set()

    # 1. Lire le fichier JSONL et collecter toutes les données
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    record = json.loads(line)
                    data.append(record)
                except json.JSONDecodeError as e:
                    print(f"Erreur de décodage JSON sur une ligne : {e}")
    except FileNotFoundError:
        print(f"Erreur : Le fichier {input_file} est introuvable.")
        return

    print(f"{len(data)} enregistrements trouvés.")

    # 2. Traiter les données pour aplatir les structures complexes et collecter les clés
    processed_data = []

    for record in data:
        flat_record = {}
        
        # Traitement spécifique pour prix_vol_par_mois
        if 'prix_vol_par_mois' in record and isinstance(record['prix_vol_par_mois'], list):
            prices = record['prix_vol_par_mois']
            # Créer une liste de 12 éléments (0 par défaut) pour les mois 1 à 12
            ordered_prices = [0] * 12
            
            for item in prices:
                if isinstance(item, dict) and 'mois' in item and 'prix_moyen_eur' in item:
                    try:
                        m = int(item['mois'])
                        p = item['prix_moyen_eur']
                        if 1 <= m <= 12:
                            ordered_prices[m-1] = p
                    except (ValueError, TypeError):
                        pass
            
            # Stocker sous forme de tableau JSON [prix_jan, prix_fev, ...]
            flat_record['prix_vol_par_mois'] = json.dumps(ordered_prices)
        
        # Traitement générique pour les autres champs
        for key, value in record.items():
            if key == 'prix_vol_par_mois':
                continue # Déjà traité
            
            if isinstance(value, (list, dict)):
                # Convertir les listes (ex: tags) et objets imbriqués en chaîne JSON
                flat_record[key] = json.dumps(value, ensure_ascii=False)
            else:
                flat_record[key] = value
        
        processed_data.append(flat_record)
        # Mettre à jour l'ensemble de toutes les clés possibles
        all_keys.update(flat_record.keys())

    # 3. Écrire le fichier CSV
    # Trier les clés pour avoir un ordre cohérent (optionnel mais propre)
    # On peut forcer certaines clés en premier si on veut (ex: input_ville, input_pays)
    sorted_keys = sorted(list(all_keys))
    
    # Petit bonus : mettre ville et pays au début si présents
    priority_keys = ['input_ville', 'input_pays', 'input_aeroport']
    for k in reversed(priority_keys):
        if k in sorted_keys:
            sorted_keys.remove(k)
            sorted_keys.insert(0, k)

    print(f"Écriture de {output_file} avec {len(sorted_keys)} colonnes...")

    try:
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=sorted_keys)
            writer.writeheader()
            writer.writerows(processed_data)
        print("Conversion terminée avec succès !")
    except IOError as e:
        print(f"Erreur lors de l'écriture du fichier CSV : {e}")

if __name__ == "__main__":
    main()
