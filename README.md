# SérendIA - Application de Recommandation de Voyage

**SérendIA** est une application mobile développée en **Flutter** qui aide les utilisateurs à découvrir leur prochaine destination de voyage idéale. Contrairement aux filtres classiques, Serendia utilise un **moteur de recommandation vectoriel** qui apprend de vos préférences et de vos interactions en temps réel.

---

## Fonctionnalités Clés

### Moteur de Recommandation Intelligent
*   **Profilage Vectoriel** : L'application convertit vos réponses (Ville vs Nature, Chill vs Actif) en un vecteur mathématique (Culture, Aventure, Détente, etc.) pour trouver les destinations les plus proches de votre "ADN de voyageur".
*   **Filtrage Souple (Soft Filtering)** : Fini les "Aucun résultat". Si une destination ne correspond pas parfaitement à vos critères (ex: budget légèrement dépassé), elle est pénalisée mais pas exclue, vous garantissant toujours des suggestions pertinentes.
*   **Apprentissage Dynamique** : L'algorithme évolue avec vous. Si vous "Likez" une destination hors de vos critères initiaux (ex: une plage en Océanie alors que vous vouliez l'Europe), le système s'adapte instantanément.

### Expérience Utilisateur Interactive
*   **Questionnaire Intuitif** : Définissez vos préférences en quelques étapes (Continents, Budget, Climat, Type de voyageur).
*   **Mini-Jeu de "Swipe"** : Affinez vos recommandations en notant rapidement 5 destinations. Chaque interaction met à jour votre profil en temps réel.
*   **Détails Enrichis** : Chaque destination affiche un score de compatibilité, une estimation budgétaire précise et un résumé des activités disponibles.

### Architecture Technique
*   **Frontend** : Flutter (Dart).
*   **Backend Local** : SQLite (`sqflite`) pour le stockage performant des milliers de destinations et activités.
*   **Data Science** : Scripts Python (`check_db.py`, `jsonl_to_csv.py`) pour le traitement et l'ingestion des données brutes.

---

## Installation et Lancement

### Prérequis
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installé.
*   Un émulateur Android/iOS ou un appareil physique connecté.

### Étapes
1.  **Cloner le projet**
    ```bash
    git clone https://github.com/votre-repo/serendia.git
    cd serendia
    ```

2.  **Installer les dépendances**
    ```bash
    flutter pub get
    ```

3.  **Lancer l'application**
    ```bash
    flutter run
    ```

---

## Historique du Développement

Ce projet a suivi une roadmap technique rigoureuse pour passer d'un simple prototype à une application intelligente :

### Phase 1 : Fondations & Données
*   [x] Modélisation des données (`Destination`, `Activity`).
*   [x] Création des scripts d'importation Python pour nettoyer les datasets CSV/JSONL.
*   [x] Migration du stockage de fichiers JSON statiques vers une base de données **SQLite** robuste.

### Phase 2 : Moteur de Recommandation V1 (Cold Start)
*   [x] Implémentation du questionnaire utilisateur.
*   [x] Création du `UserProfileVector` pour traduire les réponses en scores.
*   [x] Algorithme de "Hard Filtering" (excluant les destinations ne correspondant pas exactement).

### Phase 3 : Moteur "Enhanced" & UX
*   [x] **Correction du "Cold Start"** : Passage au "Soft Filtering" (système de pénalités) pour garantir des résultats même avec des critères stricts.
*   [x] **Boucle de Rétroaction** : Implémentation du `UserInteractionService` qui modifie le vecteur utilisateur à chaque "Like/Dislike".
*   [x] **UI Polishing** : Ajout de `RefreshIndicator`, correction des débordements de texte (Overflows), et intégration du Mini-Jeu dans le flux principal.

### Pour en savoir plus sur le Workflow algorithmique, vous pouvez consulter le fichier WORKFLOW_ALGORITHM.html
---

## Structure du Projet

```
lib/
├── main.dart           # Point d'entrée
├── models/             # Modèles de données (Destination, UserProfileVector...)
├── screens/            # Interfaces (Questionnaire, Recommandations...)
├── services/           # Logique métier (RecommendationService, DatabaseService...)
assets/
├── images/               # Fichiers jpeg
├── database/           # Base de données SQLite pré-remplie
```

---

*Développé dans le cadre du projet SAÉ-BUT3 - 2025.*

