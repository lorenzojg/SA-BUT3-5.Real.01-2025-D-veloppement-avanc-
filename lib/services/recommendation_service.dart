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
    UserProfileVector vectorUser = currentProfile ?? _createVectorFromPreferences(preferences);
    
    List<ScoredDestination> candidates = [];
    
    // Date de voyage (mois prochain par défaut si non spécifié)
    // final int targetMonth = travelMonth ?? DateTime.now().month + 1;

    for (var dest in allDestinations) {
      
      // --- Étape A : Filtrage Dur (Hard Filtering) ---
      
      // 1. Zone Géo
      if (!_matchesContinent(dest, preferences.continent)) continue;
      
      // 2. Type de voyage (Solo, Couple, Famille)
      if (!_matchesTravelType(dest, preferences.travelers)) continue;

      // 3. Climat (Simplifié pour l'instant)
      // if (!_isClimateGood(dest, preferences.prefJaugeClimat, targetMonth)) continue;
      
      // --- Étape C : Validation Budgétaire (Estimation) ---
      double estimatedCost = _calculateCost(dest, preferences);
      
      // Filtre budget strict ou souple ? Ici on applique un filtre souple
      // Si le coût dépasse le budget max estimé, on peut soit exclure, soit pénaliser le score.
      // Pour l'instant, on exclut si ça dépasse largement (> 20% tolérance)
      double? maxBudget = _parseBudget(preferences.budget);
      if (maxBudget != null && estimatedCost > maxBudget * 1.2) continue;

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
  static UserProfileVector _createVectorFromPreferences(UserPreferences prefs) {
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
  static double _calculateCost(Destination dest, UserPreferences prefs) {
    // Hypothèses simplifiées
    int durationDays = 7; // Durée standard
    int travelersCount = 1;
    
    if (prefs.travelers == 'En couple') travelersCount = 2;
    if (prefs.travelers == 'En famille') travelersCount = 4; // Moyenne

    // Coût Vie = (Coût journalier * jours) * voyageurs
    // Note: averageCost est souvent par personne par jour
    double livingCost = (dest.averageCost * durationDays) * travelersCount;
    
    // Coût Vol (Estimation grossière car on n'a pas encore la DB vols connectée ici)
    // On pourrait utiliser une moyenne basée sur la distance/continent
    double flightCostPerPerson = 500.0; // Valeur par défaut
    if (dest.continent != 'Europe') flightCostPerPerson = 1000.0;
    
    double totalFlightCost = flightCostPerPerson * travelersCount;

    return livingCost + totalFlightCost;
  }

  /// Parse le budget string en double
  static double? _parseBudget(String? budgetStr) {
    if (budgetStr == null || budgetStr == 'Sans précision de budget') return null;
    
    if (budgetStr == '< 500€') return 500.0;
    if (budgetStr == '< 500€ et > 1000€') return 1000.0; // Note: le libellé original semble bizarre (<500 et >1000 impossible), je suppose 500-1000
    if (budgetStr == '< 1000€ et > 2000€') return 2000.0; // Idem, suppose 1000-2000
    if (budgetStr == '> 2000€') return 5000.0; // Cap arbitraire haut
    
    return null;
  }

  // --- Méthodes de filtrage existantes (adaptées) ---

  static bool _matchesContinent(Destination destination, String? continent) {
    if (continent == null || continent == 'Sans préférence') return true;

    final continentMapping = {
      'Europe': ['Europe'],
      'Afrique': ['Afrique', 'Africa'],
      'Amérique du Sud': ['Amérique du Sud', 'South America'],
      'Amérique du Nord': ['Amérique du Nord', 'North America'],
      'Océanie': ['Océanie', 'Oceania'],
      'Antarctique': ['Antarctique', 'Antarctica'],
      'Asie': ['Asie', 'Asia'],
    };

    final allowedContinents = continentMapping[continent] ?? [continent];
    return allowedContinents.any((c) => destination.continent.toLowerCase() == c.toLowerCase());
  }

  static bool _matchesTravelType(Destination destination, String? travelers) {
    if (travelers == null) return true;
    
    String requiredType = 'solo';
    if (travelers == 'En couple') requiredType = 'couple';
    if (travelers == 'En famille') requiredType = 'famille';

    return destination.travelTypes.contains(requiredType);
  }
  
  // --- Méthodes Legacy (pour compatibilité si appelées ailleurs) ---
  
  static List<Destination> filterDestinations(List<Destination> destinations, UserPreferences preferences) {
    return recommend(destinations, preferences);
  }
  
  static List<Destination> sortByRelevance(List<Destination> destinations, UserPreferences preferences) {
    return recommend(destinations, preferences);
  }
}



