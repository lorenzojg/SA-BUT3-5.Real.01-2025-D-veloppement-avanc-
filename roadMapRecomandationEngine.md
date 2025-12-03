C'est un défi passionnant. Pour construire un système de recommandation pertinent (et qui ne soit pas juste une suite de `if/else`), nous allons devoir mettre en place une architecture basée sur le **Content-Based Filtering** (Filtrage basé sur le contenu) au démarrage, qui évoluera vers un système hybride grâce au **Feedback Loop** (Boucle de rétroaction).

Voici l'architecture technique et logique pour ton algorithme.

-----

### Phase 1 : La modélisation des données (La "Vectorisation")

Pour que l'algorithme puisse comparer un *Utilisateur* et une *Ville*, ils doivent parler la même langue : les mathématiques. Nous allons transformer les préférences et les villes en **Vecteurs de caractéristiques** (Feature Vectors).

#### 1\. Normalisation de la Destination

Chaque ville devient un vecteur de scores (entre 0 et 1 ou 0 et 10).
Tu as déjà : `culture`, `adventure`, `nature`, `beaches`, `nightlife`, `cuisine`, `wellness`, `urban`, `seclusion`.

  * *Milan* = `[5, 2, 2, 1, 4, 5, 3, 5, 2]` (C'est sa signature ADN).
  * *Yasawa* = `[2, 4, 5, 5, 2, 3, 4, 1, 5]`

#### 2\. Création du "Vecteur Utilisateur" (User Profile)

Au lieu de stocker juste les réponses, nous allons convertir les réponses du questionnaire en un vecteur identique à celui des villes.

  * **`pref_jauge_ville`** (0% Nature \<-\> 100% Urbain) :
      * Si 100% Urbain : Score `urban` utilisateur = 5, Score `nature` utilisateur = 1.
  * **`pref_jauge_sedentarite`** (0% Chill \<-\> 100% Actif) :
      * Si Chill : Score `wellness`/`seclusion`/`beaches` augmente.
      * Si Actif : Score `adventure`/`nightlife` augmente.
  * **`pref_travelers_type`** (Couple, Solo, Famille) : Applique un coefficient multiplicateur (biais).
      * *Couple* : Bonus sur `seclusion`, `wellness`, `cuisine`.
      * *Famille* : Bonus sur `beaches`, `nature`, Malus sur `nightlife` (ou filtre sécurité).
      * *Solo* : Bonus sur `adventure`, `nightlife`.

-----

### Phase 2 : L'Algorithme de "Cold Start" (Première Recommandation)

C'est l'étape où l'utilisateur vient de finir le questionnaire. On n'a pas encore d'historique.

**Étape A : Le Filtrage Dur (Hard Filtering)**
On élimine ce qui est impossible.

1.  **Zone Géo :** Si `pref_zone_geo` = "Europe", on ne garde que les villes `region == 'europe'`.
2.  **Calendrier & Météo :**
      * L'utilisateur est disponible en *Octobre*.
      * On regarde `avg_temp_monthly` pour le mois 10.
      * On regarde `climat_details`.
      * *Règle :* Si la température moyenne \< `seuil_acceptable` (défini par `pref_jauge_climat`), on élimine.

**Étape B : Le Calcul du Score de Compatibilité (Scoring)**
On utilise la **Distance Cosinus** ou une **Moyenne Pondérée**.
Pour chaque ville restante ($V$) et le profil utilisateur ($U$) :

$$Score(V) = W_1 \times (U_{culture} \times V_{culture}) + W_2 \times (U_{adventure} \times V_{adventure}) + ...$$

*Note : Les $W$ (Poids) peuvent être ajustés. Par exemple, si l'utilisateur a insisté sur le budget, le poids du budget augmente.*

**Étape C : La validation Budgetaire**
C'est ici qu'on utilise tes données JSON (`prix_vol_par_mois`, `hebergement`).
Pour chaque ville dans le Top 20 du scoring :

1.  **Coût Vol** = `prix_vol_par_mois` (pour le mois dispo) $\times$ nombre voyageurs.
2.  **Coût Vie** = `hebergement_moyen` $\times$ durée (ex: 7 nuits) + (Coût repas estimé $\times$ jours).
3.  **Total** = Coût Vol + Coût Vie.
4.  *Filtre :* Si Total \> `pref_budget`, on rétrograde la ville ou on la supprime (ou on la marque "Hors budget").

-----

### Phase 3 : L'Évolution (Machine Learning & Feedback Loop)

C'est là que ton algo devient "intelligent". Le **Vecteur Utilisateur** n'est pas figé. Il est vivant.

On va introduire une variable : la **Confiance** (Confidence) ou le **Poids d'apprentissage** ($\alpha$).

#### 1\. Les Signaux Explicites (Forts)

  * **Like (Cœur) :** L'utilisateur aime "Milan".
      * *Action :* On rapproche le vecteur Utilisateur du vecteur Milan.
      * *Formule :* $User_{new} = User_{old} + \alpha \times (Milan_{vector} - User_{old})$
      * *Concrètement :* Si l'utilisateur avait `Urban=3` et Milan a `Urban=5`, l'utilisateur passe à `Urban=3.2`.
  * **Dislike (Croix) :** L'utilisateur rejette "Yasawa Islands".
      * *Action :* On éloigne le vecteur Utilisateur du vecteur Yasawa.
      * *Concrètement :* Yasawa est très `Nature` et `Plage`. Le score de l'utilisateur sur ces points baisse légèrement.

#### 2\. Les Signaux Implicites (Faibles) - La subtilité

  * **Temps de réaction (Swipe rapide vs lent) :**
      * *Dislike rapide (\< 0.5s) :* Rejet viscéral. On punit fortement les tags principaux de la ville (ex: Si c'est une ville froide, on baisse drastiquement la tolérance au froid).
      * *Dislike lent (\> 2s) :* Hésitation. On punit moins sévèrement. Peut-être que c'était juste trop cher, mais que le style plaisait.
  * **Dwell Time (Temps passé sur les détails) :**
      * Si l'utilisateur clique sur "Détails", lit la description, regarde les photos, mais ne like pas forcément : C'est un **Intérêt Latent**.
      * *Action :* On booste temporairement les tags de cette ville pour les prochaines recommandations immédiates (session courante).

-----

### Phase 4 : Le "Remplissage" par les Activités (Algorithme du Sac à Dos)

Une fois la ville choisie (ex: Milan), s'il reste du budget :
`Budget_Restant = Pref_Budget - (Vol + Hotel)`.

On a une liste d'activités pour Milan. Chaque activité a un `prix` (hypothétique) et des `categories`.
On cherche à maximiser la satisfaction (`rating` + correspondance avec les tags de l'utilisateur) sans dépasser le `Budget_Restant`.

1.  Filtrer les activités par les tags préférés de l'utilisateur (ex: Si `User_Culture` est haut, prioriser "Duomo" et "Musées").
2.  Remplir le planning jusqu'à saturation du budget ou du temps.

-----

### Résumé du flux logique (Pseudo-Code)

Voici à quoi ressemblerait la fonction principale :

```dart
class RecommendationEngine {
  
  // Le "Cerveau"
  List<Destination> recommend(UserInformations userInfo, List<Destination> allDestinations) {
    
    // 1. Initialiser le profil vectoriel de l'utilisateur
    UserProfile vectorUser = _createVectorFromPreferences(userInfo.preferences);
    
    // 2. Ajuster le profil avec l'historique (Apprentissage)
    if (userInfo.history.isNotEmpty) {
       vectorUser = _applyHistoryFeedback(vectorUser, userInfo.history);
    }

    // 3. Filtrage & Scoring
    List<ScoredDestination> candidates = [];
    
    // Date de voyage (du calendrier ou par défaut mois prochain)
    int travelMonth = userInfo.availabilityMonth ?? DateTime.now().month + 1;

    for (var dest in allDestinations) {
      
      // Filtres Durs
      if (dest.region != userInfo.preferences.zoneGeo) continue;
      if (!_isClimateGood(dest, userInfo.preferences.jaugeClimat, travelMonth)) continue;
      
      // Estimation coût
      double cost = _calculateCost(dest, travelMonth, userInfo.preferences.travelersType);
      if (cost > userInfo.preferences.budget * 1.2) continue; // Marge de 20%

      // Calcul du score de similarité (Cosinus ou pondéré)
      double score = _calculateSimilarity(vectorUser, dest.scores);
      
      // Boost Score si c'est un favori archivé
      if (userInfo.favorites.contains(dest.id)) score *= 1.5;

      candidates.add(ScoredDestination(dest, score, cost));
    }

    // 4. Tri et Renvoi
    candidates.sort((a, b) => b.score.compareTo(a.score));
    
    return candidates.take(10).toList();
  }

  // L'apprentissage dynamique
  UserProfile _applyHistoryFeedback(UserProfile currentProfile, List<Interaction> history) {
    for (var interaction in history) {
       double learningRate = 0.1; // Vitesse d'apprentissage
       
       // Si swipe dislike très rapide, on apprend plus fort que ce n'est pas bon
       if (interaction.type == Dislike && interaction.time < 500ms) {
          learningRate = 0.2; 
       }
       
       // Formule mathématique de mise à jour du vecteur
       currentProfile = updateWeights(currentProfile, interaction.destinationVector, interaction.type, learningRate);
    }
    return currentProfile;
  }
}
```

### Prochaines étapes pour toi :

1.  **Normalisation des données :** Assure-toi que tes CSV et JSON sont bien nettoyés et que "Luxury" correspond bien à une tranche de prix chiffrée (ex: `Luxury` = coeff 2.5 sur le prix moyen).
2.  **Tagging :** Tes villes ont des tags (`"Mode", "Culture"`). Transforme ces tags en poids dans ton vecteur (ex: Si tag "Mode" présent -\> score `shopping` = 10).
3.  **Implémentation :** Commence simple. Fais d'abord marcher le scoring **sans** l'historique. Une fois que la reco initiale est cohérente, ajoute la brique "History Feedback".
