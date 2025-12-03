import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../models/user_profile_vector.dart';

class ScoredDestination {
  final Destination destination;
  final double score;
  final double estimatedCost;

  ScoredDestination(this.destination, this.score, this.estimatedCost);
}

class RecommendationService {
  
  /// Point d'entrée principal pour obtenir des recommandations
  static List<Destination> recommend(
      List<Destination> allDestinations,
      UserPreferences preferences,
      {int? travelMonth, UserProfileVector? currentProfile}
      ) {
    
    // 1. Initialiser le profil vectoriel de l'utilisateur
    // Si un profil courant (appris) est fourni, on l'utilise, sinon on le crée depuis les préférences
    UserProfileVector vectorUser = currentProfile ?? createVectorFromPreferences(preferences);
    
    List<ScoredDestination> candidates = [];
    
    // Date de voyage (mois prochain par défaut si non spécifié)
    final int targetMonth = travelMonth ?? (DateTime.now().month + 1);
    final int adjustedMonth = targetMonth > 12 ? targetMonth - 12 : targetMonth;

    for (var dest in allDestinations) {
      
      // --- Étape A : Filtrage Dur (Hard Filtering) ---
      
      // 1. Zone Géo (Adapté pour liste de continents)
      if (!_matchesContinent(dest, preferences.selectedContinents)) continue;
      
      // 2. Type de voyage (Solo, Couple, Famille)
      if (!_matchesTravelType(dest, preferences.travelers)) continue;

      // 3. Climat (Simplifié pour l'instant)
      // if (!_isClimateGood(dest, preferences.prefJaugeClimat, targetMonth)) continue;
      
      // --- Étape C : Validation Budgétaire (Estimation) ---
      double estimatedCost = _calculateCost(dest, preferences, adjustedMonth);
      
      // Calcul du nombre de voyageurs pour ramener le coût par personne
      int travelersCount = 1;
      if (preferences.travelers == 'En couple') travelersCount = 2;
      if (preferences.travelers == 'En famille') travelersCount = 4;
      
      double costPerPerson = estimatedCost / travelersCount;
      
      // Filtre budget strict ou souple ?
      // On mappe le niveau de budget (0-4) à un montant max estimé PAR PERSONNE
      double? maxBudgetPerPerson = _mapBudgetLevelToAmount(preferences.budgetLevel);
      
      // Si maxBudget est null (illimité) ou si le coût est dans la tolérance (+20%)
      if (maxBudgetPerPerson != null && costPerPerson > maxBudgetPerPerson * 1.2) continue;

      // --- Étape B : Calcul du Score de Compatibilité ---
      double similarityScore = _calculateSimilarity(vectorUser, dest);
      
      // Boost Score si c'est un favori archivé (TODO: intégrer UserInformations)
      // if (userInfo.favorites.contains(dest.id)) score *= 1.5;

      candidates.add(ScoredDestination(dest, similarityScore, estimatedCost));
    }

    // 4. Tri et Renvoi
    // On trie par score décroissant
    candidates.sort((a, b) => b.score.compareTo(a.score));
    
    // On retourne les destinations brutes
    return candidates.map((e) => e.destination).toList();
  }

  /// Crée un vecteur utilisateur basé sur les réponses au questionnaire
  static UserProfileVector createVectorFromPreferences(UserPreferences prefs) {
    UserProfileVector vector = UserProfileVector();

    // --- 1. Impact de la jauge Ville vs Nature ---
    // prefJaugeVille : 0.0 (Nature) <-> 1.0 (Urbain)
    vector.urban = prefs.prefJaugeVille * 5.0; // Max 5
    vector.nature = (1.0 - prefs.prefJaugeVille) * 5.0; // Max 5

    // --- 2. Impact de la jauge Sédentarité (Chill vs Actif) ---
    // prefJaugeSedentarite : 0.0 (Chill) <-> 1.0 (Actif)
    
    // Si Chill : on aime Wellness, Seclusion, Beaches
    double chillFactor = 1.0 - prefs.prefJaugeSedentarite;
    vector.wellness += chillFactor * 4.0;
    vector.seclusion += chillFactor * 3.0;
    vector.beaches += chillFactor * 2.0;

    // Si Actif : on aime Adventure, Nightlife
    double activeFactor = prefs.prefJaugeSedentarite;
    vector.adventure += activeFactor * 5.0;
    vector.nightlife += activeFactor * 3.0;

    // --- 3. Impact du Type de Voyageurs (Biais) ---
    if (prefs.travelers == 'En couple') {
      vector.seclusion += 2.0;
      vector.wellness += 1.0;
      vector.cuisine += 2.0;
    } else if (prefs.travelers == 'En famille') {
      vector.beaches += 2.0;
      vector.nature += 1.0;
      vector.nightlife -= 2.0; // Malus nightlife
    } else if (prefs.travelers == 'En solo') {
      vector.adventure += 2.0;
      vector.nightlife += 2.0;
      vector.culture += 1.0;
    }

    // --- 4. Normalisation (Optionnel mais recommandé) ---
    // Pour l'instant on garde les scores bruts pour la pondération
    
    return vector;
  }

  /// Calcule la similarité (Produit scalaire pondéré ou Cosinus)
  static double _calculateSimilarity(UserProfileVector user, Destination dest) {
    // Formule : Somme(User_i * Dest_i)
    // On peut ajouter des poids (W) si certaines catégories sont plus importantes
    
    double dotProduct = 
        (user.culture * dest.scoreCulture) +
        (user.adventure * dest.scoreAdventure) +
        (user.nature * dest.scoreNature) +
        (user.beaches * dest.scoreBeaches) +
        (user.nightlife * dest.scoreNightlife) +
        (user.cuisine * dest.scoreCuisine) +
        (user.wellness * dest.scoreWellness) +
        (user.urban * dest.scoreUrban) +
        (user.seclusion * dest.scoreSeclusion);
        
    return dotProduct;
  }

  /// Estime le coût total du voyage
  static double _calculateCost(Destination dest, UserPreferences prefs, int month) {
    // Hypothèses simplifiées
    int durationDays = 7; // Durée standard
    int travelersCount = 1;
    
    if (prefs.travelers == 'En couple') travelersCount = 2;
    if (prefs.travelers == 'En famille') travelersCount = 4; // Moyenne

    // Coût Vie = (Coût journalier * jours) * voyageurs
    // Note: averageCost est souvent par personne par jour
    double livingCost = (dest.averageCost * durationDays) * travelersCount;
    
    // Coût Vol
    double flightCostPerPerson = 500.0; // Valeur par défaut

    // Utilisation des prix mensuels si disponibles
    if (dest.monthlyFlightPrices != null && dest.monthlyFlightPrices!.isNotEmpty) {
      // month est 1-12, l'index est 0-11
      int index = (month - 1).clamp(0, 11);
      flightCostPerPerson = dest.monthlyFlightPrices![index].toDouble();
    } else {
      // Fallback si pas de données précises
      if (dest.continent != 'Europe') flightCostPerPerson = 1000.0;
    }
    
    double totalFlightCost = flightCostPerPerson * travelersCount;

    return livingCost + totalFlightCost;
  }

  /// Mappe le niveau de budget (0-4) à un montant max estimé
  static double? _mapBudgetLevelToAmount(double? level) {
    if (level == null) return null;
    int rounded = level.round();
    
    switch (rounded) {
      case 0: return 500.0; // Très petit budget
      case 1: return 1000.0; // Petit budget
      case 2: return 2000.0; // Moyen
      case 3: return 3500.0; // Élevé
      case 4: return null; // Illimité
      default: return 2000.0;
    }
  }

  // --- Méthodes de filtrage existantes (adaptées) ---

  static bool _matchesContinent(Destination destination, List<String> selectedContinents) {
    if (selectedContinents.isEmpty) return true;

    final continentMapping = {
      'Europe': ['Europe'],
      'Afrique': ['Afrique', 'Africa'],
      'Amérique du Sud': ['Amérique du Sud', 'South America'],
      'Amérique du Nord': ['Amérique du Nord', 'North America'],
      'Océanie': ['Océanie', 'Oceania'],
      'Antarctique': ['Antarctique', 'Antarctica'],
      'Asie': ['Asie', 'Asia'],
    };

    for (var selected in selectedContinents) {
      final allowed = continentMapping[selected] ?? [selected];
      if (allowed.any((c) => destination.continent.toLowerCase() == c.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesTravelType(Destination destination, String? travelers) {
    // TODO: Réactiver le filtrage quand les données 'travelTypes' contiendront 'solo', 'couple', 'famille'.
    // Actuellement, elles contiennent le niveau de budget (ex: 'Luxury').
    return true; 
    
    /*
    if (travelers == null) return true;
    
    String requiredType = 'solo';
    if (travelers == 'En couple') requiredType = 'couple';
    if (travelers == 'En famille') requiredType = 'famille';

    // Si la destination n'a pas d'info travelTypes, on accepte par défaut
    if (destination.travelTypes.isEmpty) return true;

    return destination.travelTypes.map((e) => e.toLowerCase()).contains(requiredType);
    */
  }
  
  // --- Méthodes Legacy (pour compatibilité si appelées ailleurs) ---
  
  static List<Destination> filterAndSortDestinations(List<Destination> destinations, UserPreferences preferences) {
    return recommend(destinations, preferences);
  }
  
  /// Obtient des statistiques sur les recommandations (utilisé dans recommendations_page.dart)
  static Map<String, dynamic> getRecommendationStats(
    List<Destination> originalList,
    List<Destination> filteredList,
    UserPreferences preferences,
  ) {
    // Mapping pour l'affichage des niveaux de budget
    final budgetLabels = {
      0: 'Petit budget (€)', 
      1: 'Modéré (€€)', 
      2: 'Confortable (€€€)', 
      3: 'Élevé (€€€€)', 
      4: 'Illimité (€€€€€)'
    };
    final activityDescription = _getActivityDescription(preferences.activityLevel ?? 50.0);

    return {
      'totalDestinations': originalList.length,
      'matchingDestinations': filteredList.length,
      'budget': budgetLabels[preferences.budgetLevel?.round()] ?? 'Non spécifié',
      'continent': preferences.selectedContinents.isEmpty 
                   ? 'Non spécifié' 
                   : preferences.selectedContinents.join(', '),
      'activity': activityDescription,
      'filterRate': originalList.isEmpty ? '0%' :
      '${((filteredList.length / originalList.length) * 100).toStringAsFixed(1)}%',
    };
  }
  
  static String _getActivityDescription(double level) {
    if (level < 20) return 'Très détente';
    if (level < 40) return 'Plutôt détente';
    if (level < 60) return 'Équilibré';
    if (level < 80) return 'Plutôt sportif';
    return 'Très sportif';
  }
}