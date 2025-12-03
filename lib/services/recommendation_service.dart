import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';

class RecommendationService {
  static List<Destination> filterAndSortDestinations(
    List<Destination> destinations,
    UserPreferences preferences,
  ) {
    final continents = preferences.selectedContinents ?? [];

    if (continents.isEmpty ||
        preferences.activityLevel == null ||
        preferences.budgetLevel == null) {
      return [];
    }

    // 1. Filtrer par Continent (sélection multiple)
    List<Destination> filteredByContinent = destinations.where((dest) {
      return continents.contains(dest.continent);
    }).toList();

    // 2. Filtrer par Budget
    final userBudgetLevel = preferences.budgetLevel!.round();
    List<Destination> filteredByBudget = filteredByContinent.where((dest) {
      final destinationBudgetLevel = _mapCostToBudgetLevel(dest.averageCost);
      return destinationBudgetLevel <= userBudgetLevel;
    }).toList();

    // 3. Trier par Niveau d'Activité
    filteredByBudget.sort((a, b) {
      final diffA = (a.activityScore - preferences.activityLevel!).abs();
      final diffB = (b.activityScore - preferences.activityLevel!).abs();
      return diffA.compareTo(diffB);
    });

    return filteredByBudget;
  }

  static int _mapCostToBudgetLevel(double averageCost) {
    if (averageCost <= 50) return 0;
    if (averageCost <= 150) return 1;
    if (averageCost <= 300) return 2;
    if (averageCost <= 500) return 3;
    return 4;
  }

  static Map<String, dynamic> getRecommendationStats(
    List<Destination> originalList,
    List<Destination> filteredList,
    UserPreferences preferences,
  ) {
    final budgetLabels = {
      0: 'Petit budget (€)',
      1: 'Modéré (€€)',
      2: 'Confortable (€€€)',
      3: 'Élevé (€€€€)',
      4: 'Illimité (€€€€€)'
    };

    final continents = preferences.selectedContinents ?? [];
    final continentsLabel =
        continents.isEmpty ? 'Non spécifié' : continents.join(', ');

    final activityDescription =
        _getActivityDescription(preferences.activityLevel ?? 50.0);

    return {
      'totalDestinations': originalList.length,
      'matchingDestinations': filteredList.length,
      'budget': budgetLabels[preferences.budgetLevel?.round()] ?? 'Non spécifié',
      'continent': continentsLabel,
      'activity': activityDescription,
      'filterRate': originalList.isEmpty
          ? '0%'
          : '${((filteredList.length / originalList.length) * 100).toStringAsFixed(1)}%',
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
