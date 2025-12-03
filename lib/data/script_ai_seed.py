import time
import json
import os
import re
import csv
from google import genai
from google.genai import types
from google.genai.errors import APIError

# --- 1. CONFIGURATION ---

# Décommentez et mettez votre clé ici si elle n'est pas dans les variables d'environnement
# os.environ["GEMINI_API_KEY"] = "VOTRE_CLE_API"

try:
    client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
except Exception:
    print("Erreur: La clé API GEMINI_API_KEY n'est pas configurée.")
    exit()

MODEL_NAME = "gemini-2.5-flash"

# 💡 CORRECTION CHEMINS : On utilise le dossier du script comme référence absolue
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FICHIER_ENTREE = os.path.join(SCRIPT_DIR, "Worldwide_Travel_Cities_Dataset_Ratings_and_Climate.csv")
FICHIER_SORTIE = os.path.join(SCRIPT_DIR, "resultats_voyage_complets.jsonl")

AEROPORT_DEPART = "Paris (CDG)"

# --- 2. FONCTIONS UTILITAIRES ---

def clean_json_string(text_response: str) -> str:
    """Nettoie les balises Markdown du JSON."""
    text = re.sub(r"^```json\s*", "", text_response, flags=re.MULTILINE)
    text = re.sub(r"^```\s*", "", text, flags=re.MULTILINE)
    text = re.sub(r"\s*```$", "", text, flags=re.MULTILINE)
    return text.strip()

def lire_villes_deja_traitees(fichier_sortie: str) -> set:
    """Récupère la liste des IDs ou noms des villes déjà présentes dans le fichier de sortie."""
    villes_traitees = set()
    if not os.path.exists(fichier_sortie):
        return villes_traitees
    
    with open(fichier_sortie, 'r', encoding='utf-8') as f:
        for ligne in f:
            try:
                data = json.loads(ligne)
                # On utilise la combinaison ville+pays comme identifiant unique
                if 'input_ville' in data and 'input_pays' in data:
                    identifiant = f"{data['input_ville']}|{data['input_pays']}"
                    villes_traitees.add(identifiant)
            except json.JSONDecodeError:
                continue
    return villes_traitees

# --- 3. FONCTION DE COLLECTE (UNITAIRE) ---

def collecter_donnees_destination(destination: str, pays: str, aeroport_depart: str, max_retries: int = 3) -> dict | None:
    prompt = f"""
    Trouve des informations actuelles pour un voyage au départ de {aeroport_depart} vers {destination} ({pays}).
    
    Tu dois retourner un objet JSON STRICT respectant exactement ce schéma :
    {{
        "periode_recommandee": "string (ex: Janvier à Mars)",
        "climat_details": "string (court descriptif)",
        "prix_vol_par_mois": [
            {{ "mois": 1, "prix_moyen_eur": 0 }},
            ... (pour 12 mois de 1 à 12)
        ],
        "hebergement_moyen_eur_nuit": 0,
        "tags": ["tag1", "tag2", "tag3"]
    }}
    IMPORTANT : Juste le JSON brut, pas de markdown, pas de texte avant/après.
    """
    
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="text/plain",
                    tools=[types.Tool(google_search=types.GoogleSearch())],
                )
            )

            if not response.text:
                raise ValueError("Réponse vide")

            clean_text = clean_json_string(response.text)
            data = json.loads(clean_text)
            
            # On injecte les infos d'entrée pour garder une trace dans le fichier final
            data['input_ville'] = destination
            data['input_pays'] = pays
            data['input_aeroport'] = aeroport_depart
            
            return data

        except Exception as e:
            print(f"   ⚠️ Tentative {attempt+1} échouée: {e}")
            time.sleep(2 ** attempt)
            
    return None

# --- 4. TRAITEMENT DU DATASET (BATCH) ---

def traiter_tout_le_dataset():
    if not os.path.exists(FICHIER_ENTREE):
        print(f"❌ Erreur : Le fichier est introuvable au chemin :")
        print(f"   {FICHIER_ENTREE}")
        print("   Vérifiez que le fichier est bien dans le même dossier que ce script.")
        return

    # 1. Charger l'état existant pour permettre la reprise
    villes_faites = lire_villes_deja_traitees(FICHIER_SORTIE)
    print(f"ℹ️  Reprise : {len(villes_faites)} villes déjà traitées trouvées.")

    # 2. Ouvrir le fichier de sortie en mode 'append' (ajout)
    with open(FICHIER_ENTREE, mode='r', encoding='utf-8') as csv_file, \
         open(FICHIER_SORTIE, mode='a', encoding='utf-8') as out_file:
        
        reader = csv.DictReader(csv_file)
        # On relit le fichier une fois pour compter les lignes (optionnel mais sympa pour la barre de progression)
        total_rows = sum(1 for row in csv.DictReader(open(FICHIER_ENTREE, encoding='utf-8')))
        
        print(f"🚀 Démarrage du traitement pour environ {total_rows} villes...")
        print(f"📂 Lecture de : {FICHIER_ENTREE}")
        print(f"💾 Écriture dans : {FICHIER_SORTIE}")
        
        compteur = 0
        succes = 0
        
        for row in reader:
            ville = row.get('city')
            pays = row.get('country')
            
            if not ville or not pays:
                continue

            identifiant = f"{ville}|{pays}"
            
            # Skip si déjà fait
            if identifiant in villes_faites:
                continue

            compteur += 1
            print(f"\n[{compteur}/{total_rows - len(villes_faites)}] Traitement de : {ville} ({pays})...")
            
            resultat = collecter_donnees_destination(ville, pays, AEROPORT_DEPART)
            
            if resultat:
                # Écriture immédiate dans le fichier (une ligne JSON par ville)
                json.dump(resultat, out_file, ensure_ascii=False)
                out_file.write('\n')
                out_file.flush() # Force l'écriture sur le disque
                print(f"   ✅ Sauvegardé.")
                succes += 1
            else:
                print(f"   ❌ Échec définitif pour {ville}")

            # Pause respectueuse pour l'API (Rate Limiting)
            time.sleep(2) 

    print("\n" + "="*50)
    print(f"🏁 Terminé ! {succes} nouvelles villes ajoutées.")
    print(f"📁 Résultats dans : {FICHIER_SORTIE}")

# --- 5. LANCEMENT ---

if __name__ == "__main__":
    traiter_tout_le_dataset()
