# Workflow Algorithmique - Système de Recommandation Vectoriel

## Table des matières
1. [Workflow 1 : Génération des Recommandations](#workflow-1--génération-des-recommandations)
2. [Workflow 2 : Mise à jour du Profil Utilisateur](#workflow-2--mise-à-jour-du-profil-utilisateur)

---

## Workflow 1 : Génération des Recommandations

### Point d'entrée : `recommendations_page.dart`

```dart
// Fichier: lib/screens/recommendations_page.dart
final results = await _recoService.getRecommendationsVectorBased(
  prefs: _userPreferences,
  limit: 20,
  serendipityRatio: 0.10,
  includeRecentBias: true,
  excludeIds: _shownDestinationIds,
);
```

---

### Étape 1 : `recommendation_service.dart` → `getRecommendationsVectorBased()`

**Fichier**: `lib/services/recommendation_service.dart`

#### 1.1 Conversion des préférences en vecteur
```dart
UserVector userVector = prefs.toVector();
```

**Appel vers** : `user_preferences_model.dart` → `toVector()`

**Fichier**: `lib/models/user_preferences_model.dart`
```dart
UserVector toVector() {
  final double culture = urbanLevel / 100.0;
  final double adventure = activityLevel / 100.0;
  final double nature = 1.0 - (urbanLevel / 100.0);
  
  // Utilise continentWeights si disponible, sinon poids égaux
  List<double> continentVec;
  if (continentWeights != null && continentWeights!.isNotEmpty) {
    continentVec = UserVector.weightsMapToVector(continentWeights!);
  } else {
    continentVec = UserVector.continentsToWeightedVector(selectedContinents);
  }
  
  return UserVector(
    temperature: UserVector.normalizeTemperature(minTemperature),
    budget: UserVector.normalizeBudget(budgetLevel),
    activity: activityLevel / 100.0,
    urban: urbanLevel / 100.0,
    culture: culture,
    adventure: adventure,
    nature: nature,
    continentVector: continentVec,
  );
}
```

**Résultat**: Vecteur 13D `[temp, budget, activity, urban, culture, adventure, nature, C1, C2, C3, C4, C5, C6]`

**Exemple**:
- Préférences: Europe (0.5), Afrique (0.5)
- Vecteur: `[0.5, 0.5, 0.6, 0.4, 0.4, 0.6, 0.6, 0.5, 0.5, 0, 0, 0, 0]`

---

#### 1.2 Application du biais à court terme

```dart
if (includeRecentBias) {
  userVector = _biasService.applyRecentBias(userVector);
}
```

**Appel vers**: `recent_bias_service.dart` → `applyRecentBias()`

**Fichier**: `lib/services/recent_bias_service.dart`
```dart
UserVector applyRecentBias(UserVector baseVector) {
  if (_interactions.isEmpty) return baseVector;
  
  // Récupérer les 10 dernières interactions
  final recent = _interactions.reversed.take(10).toList();
  
  // Calculer un vecteur "tendance" basé sur les likes récents
  // ...calculs...
  
  // Mélanger 90% vecteur base + 10% tendance récente
  return UserVector.interpolate(baseVector, trendVector, 0.1);
}
```

**Résultat**: Vecteur utilisateur ajusté avec les préférences récentes

---

#### 1.3 Chargement des vecteurs destinations

```dart
final allDestVectors = await _cacheService.getDestinationVectors();
final allDestinations = await _destinationService.getAllDestinations();
```

**Appel vers**: 
- `vector_cache_service.dart` → `getDestinationVectors()`
- `destination_service.dart` → `getAllDestinations()`

**Fichier**: `lib/services/vector_cache_service.dart`
```dart
Future<Map<String, DestinationVector>> getDestinationVectors() async {
  // Charge les vecteurs pré-calculés depuis SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_cacheKey);
  // ...parse JSON...
  return vectorMap; // Map<destinationId, DestinationVector>
}
```

**Résultat**: 
- `allDestVectors`: Map de ~560 vecteurs destinations
- `allDestinations`: Liste de ~560 destinations

---

### Étape 2 : Recherche des destinations sérendipité

#### 2.1 Calcul du nombre de destinations sérendipité

```dart
final serendipityCount = max(2, (limit * serendipityRatio).round());
// Avec limit=20 et ratio=0.1 → serendipityCount = 2
```

#### 2.2 Recherche des destinations sérendipité

```dart
final serendipityResults = await _computeVectorDistances(
  userVector: userVector,
  destVectors: availableDestVectors,
  enableSerendipity: true,
  continentOnly: false,
  limit: serendipityCount, // 2
);
```

**Appel vers**: `_computeVectorDistances()`

---

### Étape 3 : `_computeVectorDistances()` - Calcul sérendipité

**Fichier**: `lib/services/recommendation_service.dart`

#### 3.1 Application de la sérendipité au vecteur

```dart
final searchVector = enableSerendipity
    ? _vectorService.applySerendipity(
        userVector, 
        invertContinent: true,
        continentOnly: false,
      )
    : userVector;
```

**Appel vers**: `vector_distance_service.dart` → `applySerendipity()`

**Fichier**: `lib/services/vector_distance_service.dart`
```dart
UserVector applySerendipity(
  UserVector vector,
  {bool invertContinent = false,
  bool continentOnly = false}
) {
  if (continentOnly) {
    // Mode mini-jeu: inverse UNIQUEMENT les continents
    return _invertContinent(vector, _rng);
  } else {
    // Mode normal: inverse tout sauf continents
    final inverted = _invertAllExceptContinent(vector);
    
    if (invertContinent) {
      // Puis inverse aussi les continents
      return _invertContinent(inverted, _rng);
    }
    return inverted;
  }
}
```

**Sous-appel**: `_invertContinent()`

```dart
UserVector _invertContinent(UserVector vector, Random rng) {
  // Trouver les continents actuellement ACTIVÉS (> 0)
  final activatedIndices = <int>[];
  final inactiveIndices = <int>[];
  
  for (int i = 0; i < 6; i++) {
    if (vector.continentVector[i] > 0.05) {
      activatedIndices.add(i);
    } else {
      inactiveIndices.add(i);
    }
  }
  
  // Créer un nouveau vecteur avec UNIQUEMENT les continents non sélectionnés
  final invertedContinent = List<double>.filled(6, 0.0);
  
  // Activer 1-2 continents parmi ceux NON sélectionnés
  final numToActivate = min(rng.nextInt(2) + 1, inactiveIndices.length);
  inactiveIndices.shuffle(rng);
  
  for (int i = 0; i < numToActivate; i++) {
    invertedContinent[inactiveIndices[i]] = 1.0;
  }
  
  return vector.copyWith(continentVector: invertedContinent);
}
```

**Résultat**: Vecteur sérendipité pour mini jeu
- Vecteur base: `[0.5, 0.5, 0.6, 0.4, 0.4, 0.6, 0.6, 0.5(Europe), 0.5(Afrique), 0, 0, 0, 0]`
- Après inversion: `[0.5, 0.5, 0.6, 0.4, 0.4, 0.6, 0.6, 0, 0, 1.0(Asie), 0, 0, 0]`

---

#### 3.2 Calcul de similarité cosinus pour chaque destination

```dart
for (final entry in destVectors.entries) {
  final destVector = entry.value;
  final destination = destMap[destId];
  
  // Similarité cosinus
  final similarity = _vectorService.cosineSimilarity(
    searchVector.toArray(),
    destVector.toArray(),
  );
  
  // Score sur 100
  final score = (similarity + 1.0) * 50.0; // [-1,1] → [0,100]
  
  // Bonus activités
  final activityBonus = await _calculateActivityBonus(destination, userVector);
  
  results.add(RecommendationResult(
    destination: destination,
    totalScore: score + activityBonus,
    isSerendipity: true,
  ));
}
```

**Appel vers**: `vector_distance_service.dart` → `cosineSimilarity()`

```dart
double cosineSimilarity(List<double> vecA, List<double> vecB) {
  // Produit scalaire
  double dotProduct = 0.0;
  for (int i = 0; i < vecA.length; i++) {
    dotProduct += vecA[i] * vecB[i];
  }
  
  // Normes
  double normA = sqrt(vecA.map((x) => x * x).reduce((a, b) => a + b));
  double normB = sqrt(vecB.map((x) => x * x).reduce((a, b) => a + b));
  
  // Similarité cosinus
  return dotProduct / (normA * normB);
}
```

**Résultat**: 
- Calcul sur ~560 destinations
- Tri par score décroissant
- Retour des 2 meilleures destinations en Asie/Amérique/Océanie

---

### Zoom sur l'algorithme `_computeVectorDistances()` (Point 3.2)

**Fichier**: `lib/services/recommendation_service.dart` (lignes 628-688)

Oui, c'est **exactement ça** ! Les deux moments coûteux sont :
1. **Sérendipité** : `_computeVectorDistances()` sur ~560 destinations
2. **Par continent** : `_computeVectorDistances()` sur ~140 destinations (Europe) + ~80 (Afrique)

#### Analyse détaillée de `_computeVectorDistances()`

**Signature**:
```dart
Future<List<RecommendationResult>> _computeVectorDistances({
  required UserVector userVector,
  required Map<String, DestinationVector> destVectors,
  required bool enableSerendipity,
  bool continentOnly = false,
  required int limit,
})
```

#### Phase 1 : Application de la sérendipité (O(1))

```dart
final searchVector = enableSerendipity
    ? _vectorService.applySerendipity(
        userVector, 
        invertContinent: true,
        continentOnly: continentOnly,
      )
    : userVector;
```

**Coût**: O(1) - opération constante
- Inversion de vecteur : copie de 13 valeurs
- Sélection aléatoire de 1-2 continents

#### Phase 2 : Chargement des destinations (O(n))

```dart
final allDestinations = await _destinationService.getAllDestinations();
final destMap = {for (var d in allDestinations) d.id: d};
```

**Coût**: O(n) où n = nombre total de destinations (~560)
- Lecture depuis SQLite (mise en cache)
- Création d'une Map pour accès O(1)

#### Phase 3 : Calcul de similarité pour chaque destination (O(n × d))

```dart
for (final entry in destVectors.entries) {
  // Similarité cosinus
  final similarity = _vectorService.cosineSimilarity(
    searchVector.toArray(),    // 13D
    destVector.toArray(),       // 13D
  );
  
  // Score sur 100
  final score = (similarity + 1.0) * 50.0;
  
  // Bonus activités
  final activityBonus = await _calculateActivityBonus(destination, userVector);
  
  results.add(RecommendationResult(...));
}
```

**Coût pour UNE destination**: O(d) où d = dimension du vecteur (13)

**Détail de `cosineSimilarity()`** (lib/services/vector_distance_service.dart):
```dart
double cosineSimilarity(List<double> vecA, List<double> vecB) {
  // Produit scalaire: O(d)
  double dotProduct = 0.0;
  for (int i = 0; i < vecA.length; i++) {
    dotProduct += vecA[i] * vecB[i];
  }
  
  // Norme A: O(d)
  double normA = sqrt(vecA.map((x) => x * x).reduce((a, b) => a + b));
  
  // Norme B: O(d)
  double normB = sqrt(vecB.map((x) => x * x).reduce((a, b) => a + b));
  
  // Division: O(1)
  return dotProduct / (normA * normB);
}
```

**Opérations**:
- Produit scalaire : 13 multiplications + 12 additions = **25 ops**
- Norme A : 13 carrés + 12 additions + 1 racine carrée = **26 ops**
- Norme B : 13 carrés + 12 additions + 1 racine carrée = **26 ops**
- Division : **1 op**

**Total par destination** : ~**78 opérations** (sans bonus activités)

**Coût total Phase 3**: 
- Sérendipité : 560 destinations × 78 ops = **43 680 ops**
- Europe : 140 destinations × 78 ops = **10 920 ops**
- Afrique : 80 destinations × 78 ops = **6 240 ops**

#### Phase 4 : Tri par score décroissant (O(n log n))

```dart
// Trier par score décroissant
results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
```

**Algorithme utilisé** : **Timsort** (implémentation native de Dart)

**Caractéristiques de Timsort**:
- Hybride entre Merge Sort et Insertion Sort
- Développé par Tim Peters pour Python, adopté par Java, Dart, Swift
- Optimisé pour les données partiellement triées
- **Complexité** :
  - Meilleur cas : **O(n)** (données déjà triées)
  - Cas moyen : **O(n log n)**
  - Pire cas : **O(n log n)**
- **Mémoire** : O(n) - stable (préserve l'ordre relatif)

**Nombre de comparaisons** :
- Sérendipité : 560 destinations → ~5 600 comparaisons (560 × log₂(560) ≈ 560 × 9.13)
- Europe : 140 destinations → ~1 000 comparaisons
- Afrique : 80 destinations → ~530 comparaisons

**Coût total Phase 4**:
- Sérendipité : **~5 600 comparaisons**
- Europe : **~1 000 comparaisons**
- Afrique : **~530 comparaisons**

#### Phase 5 : Extraction des N meilleures (O(k))

```dart
return results.take(limit).toList();
```

**Coût**: O(k) où k = limit (2 pour sérendipité, 7-11 pour continents)

---

### Complexité totale de `_computeVectorDistances()`

**Formule générale** : **O(n × d + n log n)**

Où :
- n = nombre de destinations à évaluer
- d = dimension du vecteur (13)

**Simplification** : 
- d est constant (13), donc O(n × d) = O(n)
- Complexité finale : **O(n + n log n) = O(n log n)**

#### Comparaison des scénarios

| Scénario | Destinations (n) | Calcul similarité | Tri | Total approximatif |
|----------|------------------|-------------------|----|-------------------|
| **Sérendipité** | 560 | 43 680 ops | 5 600 comparaisons | **~49 000 ops** |
| **Europe** | 140 | 10 920 ops | 1 000 comparaisons | **~12 000 ops** |
| **Afrique** | 80 | 6 240 ops | 530 comparaisons | **~6 800 ops** |
| **TOTAL** | - | - | - | **~68 000 ops** |

---

### Optimisation apportée par le découpage continental

#### Avant (calcul global)

```
Calcul sur TOUTES les destinations (560)
│
├─ Similarité cosinus : 560 × 78 = 43 680 ops
├─ Tri : 560 log(560) ≈ 5 600 comparaisons
└─ Total : ~49 000 ops

Sérendipité (2 destinations)
├─ Similarité cosinus : 560 × 78 = 43 680 ops
├─ Tri : 560 log(560) ≈ 5 600 comparaisons
└─ Total : ~49 000 ops

TOTAL : ~98 000 ops
```

#### Après (calcul par continent)

```
Sérendipité (2 destinations)
├─ Similarité cosinus : 560 × 78 = 43 680 ops
├─ Tri : 560 log(560) ≈ 5 600 comparaisons
└─ Total : ~49 000 ops

Europe (7 destinations)
├─ Similarité cosinus : 140 × 78 = 10 920 ops
├─ Tri : 140 log(140) ≈ 1 000 comparaisons
└─ Total : ~12 000 ops

Afrique (11 destinations)
├─ Similarité cosinus : 80 × 78 = 6 240 ops
├─ Tri : 80 log(80) ≈ 530 comparaisons
└─ Total : ~6 800 ops

TOTAL : ~68 000 ops
```

**Gain** : **~30%** pour ce cas précis

### Pistes d'optimisation futures

#### 1. Index spatial par continent (pré-filtrage)

```dart
// Charger UNIQUEMENT les vecteurs du continent
final europeVectors = await _cacheService.getVectorsByContinent('Europe');
```

**Gain** : Éviter de charger les 560 destinations à chaque fois

#### 2. Cache des normes de vecteurs

```dart
class DestinationVector {
  final List<double> values;
  double? _cachedNorm; // Calculé une seule fois
  
  double get norm {
    _cachedNorm ??= sqrt(values.map((x) => x * x).reduce((a, b) => a + b));
    return _cachedNorm!;
  }
}
```

**Gain** : Économiser 26 ops par calcul de similarité (division de moitié)

#### 3. Tri partiel (Top-K algorithm)

Au lieu de trier toutes les destinations, utiliser un algorithme de sélection :

```dart
// Au lieu de :
results.sort(...);
return results.take(limit);

// Utiliser un QuickSelect ou MinHeap :
return selectTopK(results, limit); // O(n) au lieu de O(n log n)
```

**Gain** : 
- Sérendipité : 5 600 comparaisons → **560 comparaisons** (90% de réduction)
- Europe : 1 000 → **140**
- Afrique : 530 → **80**

**Nouveau total** : ~51 000 ops (**25% de gain**)

#### 4. Parallélisation

```dart
final results = await Future.wait([
  _computeVectorDistances(continent: 'Europe'),
  _computeVectorDistances(continent: 'Afrique'),
]);
```

**Gain** : Calculs simultanés sur multi-cœurs

---

### Étape 4 : Filtrage par continent des préférences

```dart
// Grouper destinations disponibles par continent
final byContinentVectors = <String, Map<String, DestinationVector>>{};
for (final continent in prefs.selectedContinents) {
  byContinentVectors[continent] = {};
}

for (final entry in availableDestVectors.entries) {
  final destId = entry.key;
  if (usedIds.contains(destId)) continue; // Skip sérendipité
  
  final dest = destMap[destId];
  for (final continent in prefs.selectedContinents) {
    if (DestinationService.matchesContinent(dest, continent)) {
      byContinentVectors[continent]![destId] = entry.value;
      break;
    }
  }
}
```

**Résultat**: 
- `byContinentVectors['Europe']`: ~140 destinations
- `byContinentVectors['Afrique']`: ~80 destinations

---

### Étape 5 : Calcul des poids par continent

```dart
final weights = _calculateContinentWeights(
  userVector,
  prefs.selectedContinents,
);
```

**Appel vers**: `_calculateContinentWeights()`

```dart
Map<String, double> _calculateContinentWeights(
  UserVector userVector,
  List<String> continents,
) {
  final mapping = {
    'Europe': 0,
    'Afrique': 1,
    // ...
  };
  
  final weights = <String, double>{};
  double totalWeight = 0.0;
  
  // Récupérer les poids depuis le vecteur utilisateur
  for (final continent in continents) {
    final index = mapping[continent];
    final weight = userVector.continentVector[index];
    weights[continent] = weight;
    totalWeight += weight;
  }
  
  // Normaliser pour que la somme = 1
  if (totalWeight > 0) {
    weights.updateAll((key, value) => value / totalWeight);
  }
  
  return weights;
}
```

**Résultat**: 
- `{'Europe': 0.5, 'Afrique': 0.5}` si poids égaux
- `{'Europe': 0.42, 'Afrique': 0.58}` après plusieurs likes en Afrique

---

### Étape 6 : Calcul par continent

#### 6.1 Tri des continents par poids (croissant)

```dart
final sortedContinents = weights.entries.toList()
  ..sort((a, b) => a.value.compareTo(b.value)); // Croissant
```

**Résultat**: `[('Europe', 0.42), ('Afrique', 0.58)]`

#### 6.2 Pour chaque continent : calcul des meilleures destinations

```dart
for (final entry in sortedContinents) {
  final continent = entry.key;
  final weight = entry.value;
  final continentVectors = byContinentVectors[continent]!;
  
  // Nombre de destinations à prendre (arrondi au supérieur)
  final targetCount = (weight * remainingSlots).ceil();
  // remainingSlots = 18 (20 total - 2 sérendipité)
  // Pour Afrique: (0.58 * 18).ceil() = 11
  
  // Calculer distances UNIQUEMENT pour ce continent
  final results = await _computeVectorDistances(
    userVector: userVector,
    destVectors: continentVectors,
    enableSerendipity: false,
    limit: targetCount,
  );
  
  continentResults[continent] = results;
}
```

**Résultat**:
- Europe: 7 destinations (0.42 × 18 = 7.56 → 8, mais ajusté)
- Afrique: 11 destinations (0.58 × 18 = 10.44 → 11)

**Détail du calcul pour Afrique** (même processus que sérendipité mais sans inversion):
1. Calcul similarité cosinus entre `userVector` et chaque destination d'Afrique
2. Score = (similarité + 1) × 50 + bonus activités
3. Tri par score décroissant
4. Prise des 11 meilleures

---

### Étape 7 : Combinaison avec round-robin

```dart
final normalResults = <RecommendationResult>[];
final iterators = {'Europe': 0, 'Afrique': 0};

// Round-robin jusqu'à atteindre le nombre voulu
while (normalResults.length < remainingSlots) {
  bool addedAny = false;
  
  for (final continent in prefs.selectedContinents) {
    if (normalResults.length >= remainingSlots) break;
    
    final results = continentResults[continent]!;
    final index = iterators[continent]!;
    
    if (index < results.length) {
      normalResults.add(results[index]);
      iterators[continent] = index + 1;
      addedAny = true;
    }
  }
  
  if (!addedAny) break;
}
```

**Résultat**: Alternance Europe → Afrique → Europe → Afrique...
- Liste de 18 destinations bien réparties

---

### Étape 8 : Combinaison finale et mélange

```dart
final combined = <RecommendationResult>[
  ...serendipityResults,  // 2 destinations (Asie, Océanie...)
  ...normalResults,        // 18 destinations (Europe + Afrique)
];

// Mélanger légèrement (garder top 3)
if (combined.length > 3) {
  final top3 = combined.take(3).toList();
  final rest = combined.skip(3).toList();
  rest.shuffle(Random());
  combined.clear();
  combined.addAll(top3);
  combined.addAll(rest);
}

return combined.take(limit).toList();
```

**Résultat final**: 20 destinations
- 3 meilleures destinations (non mélangées)
- 17 autres destinations (mélangées)
- 2 en mode sérendipité (continent différent)
- 18 normales (Europe + Afrique selon poids)

---

## Workflow 2 : Mise à jour du Profil Utilisateur

### Point d'entrée : `recommendations_page.dart` → `_finishGameAndRecompute()`

```dart
Future<void> _finishGameAndRecompute() async {
  if (_likedDestinations.isNotEmpty || _dislikedDestinations.isNotEmpty) {
    final updatedPrefs = _learningService.updatePreferencesFromInteractions(
      currentPrefs: _userPreferences,
      likedDestinations: _likedDestinations,
      dislikedDestinations: _dislikedDestinations,
    );
    
    setState(() {
      _userPreferences = updatedPrefs;
    });
  }
  
  // ...
  await _cacheService.clearCache();
  await _loadRecommendations();
}
```

---

### Étape 1 : `user_learning_service.dart` → `updatePreferencesFromInteractions()`

**Fichier**: `lib/services/user_learning_service.dart`

#### 1.1 Mise à jour du niveau d'activité

```dart
final newActivityLevel = _learnActivityLevel(
  currentPrefs.activityLevel,
  likedDestinations,
  dislikedDestinations,
);
```

**Détail** : `_learnActivityLevel()`

```dart
double _learnActivityLevel(
  double currentLevel,
  List<Destination> liked,
  List<Destination> disliked,
) {
  // Calculer la moyenne des niveaux d'activité des destinations likées
  double likedAvg = 0.0;
  if (liked.isNotEmpty) {
    likedAvg = liked.map((d) => DestinationService.calculateActivityScore(d))
                   .reduce((a, b) => a + b) / liked.length;
  }
  
  // Taux d'apprentissage basé sur le nombre d'interactions
  final learningRate = _calculateLearningRate(liked.length + disliked.length);
  // 3 interactions → 0.1
  // 5 interactions → 0.2
  // 10 interactions → 0.3
  
  // Nouvelle valeur: moyenne pondérée
  double targetLevel = currentLevel + (likedAvg - currentLevel) * learningRate;
  
  return targetLevel.clamp(0, 100);
}
```

**Exemple**:
- Niveau actuel: 50
- 3 destinations likées avec activité [70, 80, 75]
- Moyenne likée: 75
- Learning rate: 0.1 (3 interactions)
- Nouveau niveau: 50 + (75 - 50) × 0.1 = 52.5

---

#### 1.2 Mise à jour de la préférence urbain/nature

```dart
final newUrbanLevel = _learnUrbanLevel(
  currentPrefs.urbanLevel,
  likedDestinations,
  dislikedDestinations,
);
```

**Même logique** que pour l'activité mais sur le score urbain/nature

---

#### 1.3 Mise à jour de la température préférée

```dart
final newMinTemperature = _learnTemperaturePreference(
  currentPrefs.minTemperature,
  currentPrefs.travelMonth,
  likedDestinations,
  dislikedDestinations,
);
```

**Détail**:
```dart
double _learnTemperaturePreference(...) {
  final month = travelMonth ?? DateTime.now().month;
  
  // Extraire les températures des destinations likées
  final likedTemps = <double>[];
  for (final dest in liked) {
    final temp = DestinationService.getAvgTemp(dest, month);
    if (temp != null) likedTemps.add(temp);
  }
  
  // Calculer la température moyenne
  final avgLikedTemp = likedTemps.reduce((a, b) => a + b) / likedTemps.length;
  
  // Ajuster la température minimale (3°C en dessous pour tolérance)
  final targetMinTemp = avgLikedTemp - 3.0;
  
  final newMinTemp = currentMinTemp + (targetMinTemp - currentMinTemp) * learningRate;
  
  return newMinTemp.clamp(0, 40);
}
```

**Exemple**:
- Temp min actuelle: 15°C
- Destinations likées avec temp [22°C, 25°C, 24°C]
- Moyenne: 23.67°C
- Target: 23.67 - 3 = 20.67°C
- Learning rate: 0.1
- Nouvelle temp min: 15 + (20.67 - 15) × 0.1 = 15.57°C

---

#### 1.4 Mise à jour des poids continentaux

```dart
final newWeights = _learnContinentWeights(
  currentPrefs.selectedContinents,
  currentPrefs.continentWeights,
  likedDestinations,
);
```

**Détail** : `_learnContinentWeights()`

```dart
Map<String, double> _learnContinentWeights(...) {
  // Initialiser les poids actuels ou créer des poids égaux
  final weights = <String, double>{};
  if (currentWeights != null && currentWeights.isNotEmpty) {
    weights.addAll(currentWeights);
  } else {
    final initWeight = 1.0 / selectedContinents.length;
    for (final continent in selectedContinents) {
      weights[continent] = initWeight;
    }
  }
  
  // Compter les likes par continent
  final likeCounts = <String, int>{};
  for (final dest in liked) {
    for (final continent in allContinents) {
      if (DestinationService.matchesContinent(dest, continent)) {
        likeCounts[continent] = (likeCounts[continent] ?? 0) + 1;
        break;
      }
    }
  }
  
  // Learning rate
  final learningRate = _calculateLearningRate(liked.length) * 0.5;
  
  // Mettre à jour les poids
  likeCounts.forEach((continent, count) {
    final boost = learningRate * count;
    weights[continent] = (weights[continent] ?? 0.0) + boost;
  });
  
  // Renormaliser pour que la somme = 1
  final totalWeight = weights.values.fold(0.0, (sum, w) => sum + w);
  if (totalWeight > 0) {
    weights.updateAll((key, value) => value / totalWeight);
  }
  
  return weights;
}
```

**Exemple**:
- Poids actuels: `{'Europe': 0.5, 'Afrique': 0.5}`
- 3 destinations likées: 2 en Afrique, 1 en Europe
- Learning rate: 0.1 × 0.5 = 0.05
- Boost Afrique: 0.05 × 2 = 0.1
- Boost Europe: 0.05 × 1 = 0.05
- Avant normalisation: `{'Europe': 0.55, 'Afrique': 0.60}`
- Somme: 1.15
- Après normalisation: `{'Europe': 0.48, 'Afrique': 0.52}`

---

#### 1.5 Extraction des continents

```dart
final newContinents = newWeights.keys.toList();
```

**Résultat**: Liste des continents avec poids > 0

---

#### 1.6 Retour des préférences mises à jour

```dart
return currentPrefs.copyWith(
  activityLevel: newActivityLevel,
  urbanLevel: newUrbanLevel,
  minTemperature: newMinTemperature,
  budgetLevel: newBudgetLevel,
  selectedContinents: newContinents,
  continentWeights: newWeights,
);
```

---

### Étape 2 : Mise à jour individuelle (favoris)

**Point d'entrée**: `favorites_service.dart` → `addFavorite()`

```dart
Future<void> addFavorite(Destination destination) async {
  // Ajouter aux favoris dans la base
  // ...
  
  // Mettre à jour les préférences
  final currentPrefs = await PreferencesService.loadUserPreferences();
  if (currentPrefs != null) {
    final updatedPrefs = UserLearningService().updateFromSingleInteraction(
      currentPrefs: currentPrefs,
      destination: destination,
      isLike: true,
    );
    await PreferencesService.saveUserPreferences(updatedPrefs);
    
    // Invalider le cache
    await RecommendationsCacheService().clearCache();
  }
}
```

**Appel vers**: `user_learning_service.dart` → `updateFromSingleInteraction()`

```dart
UserPreferencesV2 updateFromSingleInteraction({
  required UserPreferencesV2 currentPrefs,
  required Destination destination,
  required bool isLike,
}) {
  const learningRate = 0.05; // Faible pour une seule interaction
  
  if (isLike) {
    // Trouver le continent de la destination
    String? destContinent;
    for (final continent in allContinents) {
      if (DestinationService.matchesContinent(destination, continent)) {
        destContinent = continent;
        break;
      }
    }
    
    // Mettre à jour les poids continentaux
    final weights = Map<String, double>.from(currentPrefs.continentWeights ?? {});
    if (weights.isEmpty) {
      // Initialiser avec poids égaux
      for (final c in currentPrefs.selectedContinents) {
        weights[c] = 1.0 / currentPrefs.selectedContinents.length;
      }
    }
    
    if (destContinent != null) {
      weights[destContinent] = (weights[destContinent] ?? 0.0) + learningRate;
      
      // Renormaliser
      final sum = weights.values.fold(0.0, (a, b) => a + b);
      if (sum > 0) {
        weights.updateAll((key, value) => value / sum);
      }
    }
    
    // Ajouter le continent s'il n'est pas dans la liste
    final newContinents = List<String>.from(currentPrefs.selectedContinents);
    if (destContinent != null && !newContinents.contains(destContinent)) {
      newContinents.add(destContinent);
    }
    
    return currentPrefs.copyWith(
      activityLevel: currentPrefs.activityLevel + (destActivity - currentPrefs.activityLevel) * learningRate,
      urbanLevel: currentPrefs.urbanLevel + (destUrban - currentPrefs.urbanLevel) * learningRate,
      minTemperature: destTemp != null 
          ? currentPrefs.minTemperature + (destTemp - 3.0 - currentPrefs.minTemperature) * learningRate
          : currentPrefs.minTemperature,
      selectedContinents: newContinents,
      continentWeights: weights,
    );
  }
}
```

**Exemple**:
- Poids actuels: `{'Europe': 0.48, 'Afrique': 0.52}`
- Like sur une destination en Afrique
- Learning rate: 0.05
- Nouveau poids Afrique: 0.52 + 0.05 = 0.57
- Avant normalisation: `{'Europe': 0.48, 'Afrique': 0.57}`
- Somme: 1.05
- Après normalisation: `{'Europe': 0.457, 'Afrique': 0.543}`

---

### Étape 3 : Application du biais court terme

**Lors du prochain calcul** dans `getRecommendationsVectorBased()`:

```dart
if (includeRecentBias) {
  userVector = _biasService.applyRecentBias(userVector);
}
```

**Fichier**: `lib/services/recent_bias_service.dart`

```dart
UserVector applyRecentBias(UserVector baseVector) {
  if (_interactions.isEmpty) return baseVector;
  
  // Récupérer les 10 dernières interactions (dans les 7 derniers jours)
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final recent = _interactions
      .where((i) => i.timestamp.isAfter(cutoff))
      .toList()
      .reversed
      .take(10)
      .toList();
  
  if (recent.isEmpty) return baseVector;
  
  // Créer un vecteur "tendance" basé sur les destinations récentes
  final likedDestinations = recent
      .where((i) => i.action == 'like')
      .map((i) => i.destination)
      .toList();
  
  if (likedDestinations.isEmpty) return baseVector;
  
  // Calculer la moyenne des vecteurs des destinations likées
  // ...
  
  // Mélanger 90% base + 10% tendance
  return UserVector.interpolate(baseVector, trendVector, 0.1);
}
```

**Résultat**: Le vecteur utilisateur est légèrement ajusté vers les destinations récemment likées

---

## Résumé visuel

### Workflow Recommandations
```
recommendations_page.dart
  ↓
recommendation_service.dart → getRecommendationsVectorBased()
  ↓
├─ user_preferences_model.dart → toVector()
│   └─ user_vector_model.dart → weightsMapToVector()
│
├─ recent_bias_service.dart → applyRecentBias()
│
├─ vector_cache_service.dart → getDestinationVectors()
│
├─ SÉRENDIPITÉ (2 destinations)
│   ├─ vector_distance_service.dart → applySerendipity()
│   │   └─ _invertContinent() → Asie/Océanie au lieu d'Europe/Afrique
│   │
│   └─ Pour chaque destination (~560)
│       ├─ cosineSimilarity(vecteurSérendipité, vecteurDestination)
│       ├─ score = (similarité + 1) × 50
│       └─ TOP 2
│
└─ RECOMMANDATIONS NORMALES (18 destinations)
    ├─ Filtrage par continent (Europe, Afrique)
    │
    ├─ Calcul des poids (depuis vecteur utilisateur)
    │   Europe: 0.48, Afrique: 0.52
    │
    ├─ Pour CHAQUE continent:
    │   ├─ Nombre cible = poids × 18
    │   │   Europe: 9, Afrique: 9
    │   │
    │   └─ Pour chaque destination du continent
    │       ├─ cosineSimilarity(vecteurUser, vecteurDestination)
    │       ├─ score = (similarité + 1) × 50 + bonusActivités
    │       └─ TOP N destinations
    │
    └─ Round-robin: Europe → Afrique → Europe → Afrique...
```

### Workflow Mise à jour profil
```
recommendations_page.dart → _finishGameAndRecompute()
  ↓
user_learning_service.dart → updatePreferencesFromInteractions()
  ↓
├─ _learnActivityLevel()
│   └─ Moyenne des destinations likées
│   └─ currentLevel + (moyenne - current) × learningRate
│
├─ _learnUrbanLevel()
│   └─ Même logique pour urbain/nature
│
├─ _learnTemperaturePreference()
│   └─ Moyenne températures - 3°C
│
├─ _learnBudgetPreference()
│   └─ Moyenne budgets likés
│
└─ _learnContinentWeights()
    ├─ Compter likes par continent
    ├─ Boost = learningRate × count
    ├─ newWeight = oldWeight + boost
    └─ Renormalisation (somme = 1)
```

### Favoris (mise à jour individuelle)
```
favorites_service.dart → addFavorite()
  ↓
user_learning_service.dart → updateFromSingleInteraction()
  ↓
├─ Identifier le continent de la destination
├─ weights[continent] += 0.05
├─ Renormalisation
└─ Ajustement léger des autres préférences
```

### Biais court terme
```
recent_bias_service.dart → applyRecentBias()
  ↓
├─ Récupérer les 10 derniers likes (7 jours)
├─ Créer un vecteur "tendance"
└─ Mélanger 90% base + 10% tendance
```

---

## 📊 Exemple complet pas à pas

### Situation initiale
- Préférences: Europe, Afrique (poids égaux 0.5/0.5)
- Activité: 50, Urbain: 40, Temp min: 15°C

### Mini-jeu : 5 choix
1. ✅ Marrakech (Afrique) - Activité: 60, Urbain: 70, Temp: 22°C
2. ✅ Le Cap (Afrique) - Activité: 55, Urbain: 65, Temp: 20°C
3. ❌ Berlin (Europe) - Activité: 40, Urbain: 90
4. ✅ Nairobi (Afrique) - Activité: 70, Urbain: 60, Temp: 19°C
5. ❌ Amsterdam (Europe) - Activité: 35, Urbain: 85

### Après le mini-jeu (updatePreferencesFromInteractions)

**Activité**:
- Likées: [60, 55, 70] → moyenne = 61.67
- Learning rate: 0.2 (5 interactions)
- Nouveau: 50 + (61.67 - 50) × 0.2 = 52.33

**Urbain**:
- Likées: [70, 65, 60] → moyenne = 65
- Nouveau: 40 + (65 - 40) × 0.2 = 45

**Température**:
- Likées: [22, 20, 19] → moyenne = 20.33°C
- Target: 20.33 - 3 = 17.33°C
- Nouveau: 15 + (17.33 - 15) × 0.2 = 15.47°C

**Poids continents**:
- Likes: 3 Afrique, 0 Europe
- Boost Afrique: 0.1 × 3 = 0.3
- Avant norm: {Europe: 0.5, Afrique: 0.8}
- Après norm: {Europe: 0.38, Afrique: 0.62}

### Ajout d'un favori : Le Caire (Afrique)

**updateFromSingleInteraction**:
- Learning rate: 0.05
- weights[Afrique]: 0.62 + 0.05 = 0.67
- Après norm: {Europe: 0.36, Afrique: 0.64}

### Prochain calcul de recommandations

**Répartition** (sur 18 places normales):
- Europe: 0.36 × 18 = 6.48 → 7 destinations
- Afrique: 0.64 × 18 = 11.52 → 11 destinations

**Plus** 2 destinations sérendipité (Asie, Océanie...)

**Total**: 20 recommandations adaptées au nouveau profil
