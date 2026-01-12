# 🗑️ Guide de Nettoyage - Code Inutile à Supprimer

## ✅ NOUVEAU SYSTÈME (À GARDER)

### Modèles
- ✅ `models/user_preferences_v2.dart` - Nouveau modèle de préférences utilisateur
- ✅ `models/destination_v2.dart` - Modèle adapté aux vraies données DB
- ✅ `models/activity_v2.dart` - Modèle adapté aux vraies données DB

### Services
- ✅ `services/database_service_v2.dart` - Service DB qui lit directement bd.db
- ✅ `services/recommendation_service_v2.dart` - Service de recommandation simplifié
- ✅ `services/user_learning_service.dart` - Service d'apprentissage like/dislike
- ✅ `services/favorites_service.dart` - À garder, toujours utile

---

## ❌ ANCIEN SYSTÈME (À SUPPRIMER OU ADAPTER)

### 1. Services Inutiles

#### ❌ `services/data_loader_service.dart`
**Raison**: Charge les données depuis CSV, mais maintenant on utilise directement bd.db
**Action**: SUPPRIMER complètement
**Impact**: Supprime ~400 lignes de code de parsing CSV complexe

#### ❌ `services/activity_analyzer_service.dart`
**Raison**: 
- Charge les prix depuis CSV (`prixMoyens.csv`)
- Calcule des scores d'activités de manière complexe
- Tout ça est maintenant dans `ActivityV2.calculateActivityScore()`
**Action**: SUPPRIMER complètement
**Impact**: ~150 lignes de code redondant

#### ⚠️ `services/enhanced_recommendation_service.dart`
**Raison**: Surcouche complexe qui mélange ancien et nouveau système
**Action**: SUPPRIMER ou fusionner dans `recommendation_service_v2.dart`
**Impact**: ~350 lignes de code redondant

#### ⚠️ `services/recommendation_service.dart` (ancien)
**Raison**: Utilise l'ancien système de vecteurs (UserProfileVector)
**Action**: SUPPRIMER après migration complète
**Impact**: ~200 lignes de logique obsolète

#### ⚠️ `services/user_interaction_service.dart`
**Raison**: Fait la même chose que `user_learning_service.dart` mais de manière moins claire
**Action**: SUPPRIMER après vérification qu'il n'est plus utilisé
**Impact**: ~100 lignes

---

### 2. Modèles Obsolètes

#### ⚠️ `models/destination_model.dart` (ancien)
**Raison**: Structure ne correspond pas aux vraies données DB
**Utilise**: `activities: List<String>`, `averageCost`, `climate` (string)
**Problème**: Les vraies données ont `avg_temp_monthly` (JSON), `budget_level`, `prix_vol_par_mois`
**Action**: REMPLACER toutes les utilisations par `DestinationV2`

#### ⚠️ `models/activity_model.dart` (ancien)
**Raison**: Structure simplifiée, ne correspond pas aux vraies données
**Manque**: `description`, `address`, `type`, `estimated_price_euro`
**Action**: REMPLACER par `ActivityV2`

#### ⚠️ `models/user_profile_vector.dart`
**Raison**: Vecteur complexe avec 9 dimensions (culture, adventure, nature, etc.)
**Problème**: Ne prend pas en compte budget, température, continent
**Action**: SUPPRIMER, remplacé par `UserPreferencesV2`

#### ⚠️ `models/questionnaire_model.dart`
**Raison**: Ancien modèle `UserPreferences` avec des champs incohérents
**Action**: Adapter pour utiliser `UserPreferencesV2` ou créer un adaptateur

---

### 3. Fichiers CSV Inutiles

Puisque vous avez `bd.db` qui contient tout, ces fichiers CSV ne servent plus :

#### ❌ À SUPPRIMER :
- `assets/data/activities.csv` → Données dans `bd.db` table `activite`
- `assets/data/city_data.csv` → Données dans `bd.db` table `destinations`
- `assets/data/hotel_prices_by_city.csv` → Données dans colonnes `prix-moyen-hotel-*`
- `assets/data/prixMoyens.csv` → Non utilisé dans le nouveau système
- `assets/data/Worldwide_Travel_Cities_Dataset_Ratings_and_Climate.csv` → Dans `bd.db`

#### ✅ À GARDER (si utilisés ailleurs) :
- `assets/destinations.json` - Vérifier si utilisé
- `assets/database/destination.csv` - Référence seulement
- `assets/database/activite.csv` - Référence seulement

---

## 🔄 PLAN DE MIGRATION

### Étape 1: Mettre à jour SplashScreen
```dart
// Avant (dans splash_screen.dart)
await DataLoaderService().loadInitialData(); // ❌ SUPPRIMER

// Après
await DatabaseServiceV2().database; // ✅ Juste vérifier que la DB est copiée
```

### Étape 2: Adapter les Pages qui utilisent les recommandations

#### Dans `recommendations_page.dart` ou équivalent:
```dart
// Avant
final service = EnhancedRecommendationService();
await service.initialize(preferences: prefs);
final destinations = await service.getEnhancedRecommendations(allDest);

// Après
final service = RecommendationServiceV2();
final results = await service.getRecommendations(
  prefs: prefsV2,
  limit: 10,
  includeActivities: true,
);
// results contient les destinations ET les activités triées
```

### Étape 3: Adapter le mini-jeu like/dislike

```dart
// Après 5 interactions
final learningService = UserLearningService();
final updatedPrefs = learningService.updatePreferencesFromInteractions(
  currentPrefs: currentPrefs,
  likedDestinations: likedDests,
  dislikedDestinations: dislikedDests,
);

// Sauvegarder les nouvelles préférences
await saveUserPreferences(updatedPrefs);

// Re-calculer les recommandations avec les nouvelles préférences
final newResults = await RecommendationServiceV2().getRecommendations(
  prefs: updatedPrefs,
);
```

### Étape 4: Mettre à jour database_service.dart (ancien)

Option A: **SUPPRIMER** complètement et utiliser `database_service_v2.dart` partout

Option B: **ADAPTER** pour qu'il utilise bd.db au lieu de créer les tables
```dart
// Dans _initializeDatabase()
// Avant: Copier depuis assets ou créer des tables
// Après: Utiliser directement bd.db comme dans database_service_v2.dart
```

---

## 📊 RÉSUMÉ DES GAINS

### Code à supprimer:
- **~1200 lignes** de code obsolète
- **5 fichiers CSV** (~2MB) inutiles
- **3-4 services** redondants

### Avantages:
- ✅ **Performances**: Lecture directe depuis SQLite (pas de parsing CSV)
- ✅ **Simplicité**: 1 seul service de recommandation au lieu de 3
- ✅ **Cohérence**: Modèles alignés avec les vraies données DB
- ✅ **Maintenance**: Moins de code = moins de bugs

---

## ⚠️ POINTS D'ATTENTION

### À vérifier avant suppression:

1. **Rechercher toutes les importations** de l'ancien code:
   ```bash
   # Dans le terminal
   grep -r "import.*destination_model.dart" lib/
   grep -r "import.*recommendation_service.dart" lib/
   grep -r "DataLoaderService" lib/
   ```

2. **Tester que bd.db contient bien toutes les données**:
   ```dart
   final db = DatabaseServiceV2();
   final stats = await db.getStats();
   print(stats); // Vérifier nombre de destinations et activités
   ```

3. **Sauvegarder l'ancien code** (au cas où):
   ```bash
   git checkout -b backup-old-system
   git add .
   git commit -m "Backup avant suppression ancien système"
   ```

---

## 🎯 ORDRE DE SUPPRESSION RECOMMANDÉ

1. ✅ **D'abord**: Migrer les pages/écrans vers le nouveau système
2. ✅ **Ensuite**: Supprimer les imports de l'ancien système
3. ✅ **Après tests**: Supprimer les fichiers de services obsolètes
4. ✅ **Enfin**: Supprimer les CSV et nettoyer assets/

---

## 💡 QUESTIONS FRÉQUENTES

**Q: Et si j'ai besoin de l'ancien système temporairement?**
R: Gardez les fichiers avec un suffixe `_legacy.dart` le temps de la migration

**Q: Comment migrer les préférences utilisateur sauvegardées?**
R: Utilisez `UserPreferencesV2.fromLegacy(oldPrefs)` pour convertir

**Q: Les favoris sont-ils affectés?**
R: Non, `FavoritesService` reste identique et fonctionne avec les IDs de destinations

**Q: Comment tester le nouveau système?**
R: Créez un fichier de test qui compare les résultats ancien vs nouveau
