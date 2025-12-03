import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';

class RecommendationService {
  // Correction: La méthode filterDestinations doit utiliser la nouvelle logique de préférences.
  static List<Destination> filterAndSortDestinations(
    List<Destination> destinations,
    UserPreferences preferences,
  ) {
    if (preferences.selectedContinents.isEmpty ||
        preferences.activityLevel == null ||
        preferences.budgetLevel == null) {
      return [];
    }

    // 1. Filtrer par Continent (sélection multiple)
    List<Destination> filteredByContinent = destinations.where((dest) {
      return preferences.selectedContinents.contains(dest.continent);
    }).toList();

    // 2. Filtrer par Budget (score de la destination <= niveau de budget utilisateur)
    final userBudgetLevel = preferences.budgetLevel!.round();
    List<Destination> filteredByBudget = filteredByContinent.where((dest) {
      // Nous devons définir une fonction pour mapper l'averageCost au budgetScore 0-4
      // Pour l'instant, faisons un mapping simple
      final destinationBudgetLevel = _mapCostToBudgetLevel(dest.averageCost);
      return destinationBudgetLevel <= userBudgetLevel;
    }).toList();

    // 3. Trier par Niveau d'Activité (plus la différence est faible, meilleur est le match)
    filteredByBudget.sort((a, b) {
      // Calculer l'écart entre le score d'activité de la destination et la préférence utilisateur
      final diffA = (a.activityScore - preferences.activityLevel!).abs();
      final diffB = (b.activityScore - preferences.activityLevel!).abs();
      return diffA.compareTo(diffB); // Trie par l'écart le plus faible
    });

    // Retourne l'ensemble des destinations filtrées et triées
    return filteredByBudget;
  }

  // Helper pour convertir averageCost en niveau de budget (0-4)
  static int _mapCostToBudgetLevel(double averageCost) {
    if (averageCost <= 50) return 0; // €
    if (averageCost <= 150) return 1; // €€
    if (averageCost <= 300) return 2; // €€€
    if (averageCost <= 500) return 3; // €€€€
    return 4; // €€€€€
  }

  /// Trie les destinations par pertinence (score de recommandation)
  // Correction: Cette fonction est désormais obsolète car nous filtrons/trions directement dans filterAndSortDestinations
  // On peut la supprimer ou la garder pour un tri secondaire si on le souhaite.
  // Dans le contexte du projet, le tri par activité (point 3 ci-dessus) est le tri principal.
  
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
      'continent': preferences.selectedContinents.join(', ') == '' 
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