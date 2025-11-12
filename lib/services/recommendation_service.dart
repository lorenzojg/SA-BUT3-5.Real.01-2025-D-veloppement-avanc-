import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';

class RecommendationService {
  /// Filtre les destinations selon les préférences de l'utilisateur
  static List<Destination> filterDestinations(
      List<Destination> destinations,
      UserPreferences preferences,
      ) {
    return destinations.where((destination) {
      // 1️⃣ Filtrer par budget
      if (!_matchesBudget(destination, preferences.budget)) {
        return false;
      }

      // 2️⃣ Filtrer par continent
      if (!_matchesContinent(destination, preferences.continent)) {
        return false;
      }

      // 3️⃣ Filtrer par type de voyage
      if (!_matchesTravelType(destination, preferences.travelers)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Vérifie si la destination correspond au budget
  static bool _matchesBudget(Destination destination, String? budget) {
    if (budget == null || budget == 'Sans précision de budget') {
      return true;
    }

    final cost = destination.averageCost;

    // Budget < 500€
    if (budget == '< 500€' && cost <= 500) {
      return true;
    }

    // Budget entre 500€ et 1000€
    if (budget == '< 500€ et > 1000€' && cost > 500 && cost <= 1000) {
      return true;
    }

    // Budget entre 1000€ et 2000€
    if (budget == '< 1000€ et > 2000€' && cost > 1000 && cost <= 2000) {
      return true;
    }

    // Budget > 2000€
    if (budget == '> 2000€' && cost > 2000) {
      return true;
    }

    return false;
  }

  /// Vérifie si la destination correspond au continent choisi
  static bool _matchesContinent(Destination destination, String? continent) {
    if (continent == null || continent == 'Sans préférence') {
      return true;
    }

    // Mapper les continents français vers ceux du dataset
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

    return allowedContinents.any((c) =>
    destination.continent.toLowerCase() == c.toLowerCase());
  }

  /// Vérifie si la destination correspond au type de voyage
  static bool _matchesTravelType(Destination destination, String? travelers) {
    if (travelers == null) {
      return true;
    }

    // Mapper les choix du questionnaire vers les types de voyage
    String travelType;
    if (travelers == 'En solo') {
      travelType = 'solo';
    } else if (travelers == 'En couple') {
      travelType = 'couple';
    } else if (travelers == 'En famille') {
      travelType = 'famille';
    } else {
      return true;
    }

    return destination.travelTypes.contains(travelType);
  }

  /// Trie les destinations par pertinence (score de recommandation)
  static List<Destination> sortByRelevance(
      List<Destination> destinations,
      UserPreferences preferences,
      ) {
    // Créer une liste avec scores
    final destinationsWithScores = destinations.map((dest) {
      return {
        'destination': dest,
        'score': _calculateRelevanceScore(dest, preferences),
      };
    }).toList();

    // Trier par score décroissant
    destinationsWithScores.sort((a, b) {
      final scoreA = a['score'] as int;
      final scoreB = b['score'] as int;
      return scoreB.compareTo(scoreA);
    });

    // Retourner seulement les destinations triées
    return destinationsWithScores
        .map((item) => item['destination'] as Destination)
        .toList();
  }

  /// Calcule un score de pertinence pour une destination
  static int _calculateRelevanceScore(
      Destination destination,
      UserPreferences preferences,
      ) {
    int score = 0;

    // Bonus si le continent correspond exactement
    if (preferences.continent != null &&
        preferences.continent != 'Sans préférence') {
      if (_matchesContinent(destination, preferences.continent)) {
        score += 5;
      }
    }

    // Bonus si le type de voyage correspond
    if (preferences.travelers != null) {
      if (_matchesTravelType(destination, preferences.travelers)) {
        score += 3;
      }
    }

    // Bonus si le budget correspond parfaitement
    if (preferences.budget != null &&
        preferences.budget != 'Sans précision de budget') {
      if (_matchesBudget(destination, preferences.budget)) {
        score += 2;
      }
    }

    // Bonus pour les destinations bien notées
    if (destination.rating >= 4.5) {
      score += 2;
    }

    // Bonus pour les sites UNESCO
    if (destination.unescoSite) {
      score += 1;
    }

    return score;
  }

  /// Obtient des statistiques sur les recommandations
  static Map<String, dynamic> getRecommendationStats(
      List<Destination> originalList,
      List<Destination> filteredList,
      UserPreferences preferences,
      ) {
    return {
      'totalDestinations': originalList.length,
      'matchingDestinations': filteredList.length,
      'budget': preferences.budget ?? 'Non spécifié',
      'continent': preferences.continent ?? 'Non spécifié',
      'travelers': preferences.travelers ?? 'Non spécifié',
      'filterRate':
      '${((filteredList.length / originalList.length) * 100).toStringAsFixed(1)}%',
    };
  }
}
