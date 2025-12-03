import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../models/user_interaction_model.dart';
import 'activity_analyzer_service.dart';

export 'activity_analyzer_service.dart' show Activity;

/// Service de recommandation enrichi qui utilise les données CSV d'activités et de prix
class EnhancedRecommendationService {
  static final EnhancedRecommendationService _instance =
      EnhancedRecommendationService._internal();

  factory EnhancedRecommendationService() {
    return _instance;
  }

  EnhancedRecommendationService._internal();

  final ActivityAnalyzerService _activityAnalyzer = ActivityAnalyzerService();
  final List<UserInteraction> _interactionHistory = [];
  late UserPreferences _basePreferences;

  /// Initialise le service avec les préférences de l'utilisateur
  void initialize({required UserPreferences preferences}) async {
    _basePreferences = preferences;
    // Charger les données CSV au démarrage
    await _activityAnalyzer.loadActivities();
    await _activityAnalyzer.loadPrices();
    print('✅ EnhancedRecommendationService initialisé avec données CSV');
  }

  /// Enregistre une interaction utilisateur
  void recordInteraction(String destinationId, InteractionType type) {
    _interactionHistory.add(
      UserInteraction(
        destinationId: destinationId,
        type: type,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Analyse les préférences apprises depuis les interactions
  Map<String, dynamic> _analyzeLearnedPreferences(
    List<Destination> allDestinations,
  ) {
    final likedIds =
        _interactionHistory
            .where((i) => i.type == InteractionType.like)
            .map((i) => i.destinationId)
            .toSet();

    final likedDestinations =
        allDestinations.where((dest) => likedIds.contains(dest.id)).toList();

    if (likedDestinations.isEmpty) {
      return {};
    }

    // Moyenne des scores d'activité
    final avgActivityScore =
        likedDestinations.fold<double>(
          0,
          (sum, dest) => sum + dest.activityScore,
        ) /
        likedDestinations.length;

    // Analyse des catégories d'activités depuis le CSV
    final allActivities = <Activity>[];
    for (final dest in likedDestinations) {
      allActivities.addAll(
        _activityAnalyzer.getActivitiesForDestination(dest.name),
      );
    }

    final categoryFrequency = <String, int>{};
    for (final activity in allActivities) {
      for (final cat in activity.getPrimaryCategories()) {
        categoryFrequency[cat] = (categoryFrequency[cat] ?? 0) + 1;
      }
    }

    // Continents et pays aimés
    final continentsLiked = <String, int>{};
    for (final dest in likedDestinations) {
      continentsLiked[dest.continent] =
          (continentsLiked[dest.continent] ?? 0) + 1;
    }

    return {
      'avgActivityScore': avgActivityScore,
      'categoryFrequency': categoryFrequency,
      'continentsLiked': continentsLiked,
      'likedCount': likedDestinations.length,
      'topActivities': allActivities.take(10).toList(),
    };
  }

  /// Calcule un score amélioré pour chaque destination
  double _calculateEnhancedScore(
    Destination destination,
    Map<String, dynamic> learnedPrefs,
  ) {
    if (learnedPrefs.isEmpty) {
      return 0.0;
    }

    double score = 0.0;

    // 1. Score d'activité basé sur le CSV (30 points)
    final enhancedActivityScore = _activityAnalyzer
        .calculateEnhancedActivityScore(destination, _basePreferences);
    final activityDiff =
        (enhancedActivityScore - (learnedPrefs['avgActivityScore'] as double))
            .abs();
    score += (1 - (activityDiff / 100)).clamp(0, 1) * 30;

    // 2. Score de catégories d'activités (25 points)
    final destActivities = _activityAnalyzer.getActivitiesForDestination(
      destination.name,
    );
    if (destActivities.isNotEmpty) {
      final categoryFreq =
          learnedPrefs['categoryFrequency'] as Map<String, int>;
      int matchingCats = 0;
      for (final activity in destActivities) {
        for (final cat in activity.getPrimaryCategories()) {
          if (categoryFreq.containsKey(cat)) {
            matchingCats += categoryFreq[cat]!;
          }
        }
      }
      score += (matchingCats / destActivities.length).clamp(0, 1) * 25;
    }

    // 3. Score de continent (20 points)
    final continentsLiked = learnedPrefs['continentsLiked'] as Map<String, int>;
    if (continentsLiked.containsKey(destination.continent)) {
      score += 20;
    }

    // 4. Score de note (15 points)
    score += (destination.rating / 5) * 15;

    // 5. Score de diversité des activités (10 points)
    if (destActivities.length > 5) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Recommande les meilleures destinations basées sur l'apprentissage et le CSV
  List<Destination> getEnhancedRecommendations(
    List<Destination> allDestinations, {
    int limit = 10,
  }) {
    final learnedPrefs = _analyzeLearnedPreferences(allDestinations);

    // Si peu d'interactions, utiliser les préférences de base
    if (learnedPrefs.isEmpty) {
      return _getBaseRecommendations(allDestinations, limit);
    }

    // Scorer chaque destination
    final scoredDestinations =
        allDestinations.map((dest) {
          final score = _calculateEnhancedScore(dest, learnedPrefs);
          return {'destination': dest, 'score': score};
        }).toList();

    // Trier par score décroissant
    scoredDestinations.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    return scoredDestinations
        .take(limit)
        .map((item) => item['destination'] as Destination)
        .toList();
  }

  /// Recommandations basées sur les préférences initiales
  List<Destination> _getBaseRecommendations(
    List<Destination> allDestinations,
    int limit,
  ) {
    if (_basePreferences.selectedContinents.isEmpty ||
        _basePreferences.activityLevel == null ||
        _basePreferences.budgetLevel == null) {
      return [];
    }

    List<Destination> filtered =
        allDestinations.where((dest) {
          return _basePreferences.selectedContinents.contains(dest.continent);
        }).toList();

    final userBudgetLevel = _basePreferences.budgetLevel!.round();
    filtered =
        filtered.where((dest) {
          final destBudgetLevel = _mapCostToBudgetLevel(dest.averageCost);
          return destBudgetLevel <= userBudgetLevel;
        }).toList();

    filtered.sort((a, b) {
      final diffA = (a.activityScore - _basePreferences.activityLevel!).abs();
      final diffB = (b.activityScore - _basePreferences.activityLevel!).abs();
      return diffA.compareTo(diffB);
    });

    return filtered.take(limit).toList();
  }

  /// Mappe le coût à un niveau de budget
  static int _mapCostToBudgetLevel(double averageCost) {
    if (averageCost <= 50) return 0;
    if (averageCost <= 150) return 1;
    if (averageCost <= 300) return 2;
    if (averageCost <= 500) return 3;
    return 4;
  }

  /// Obtient des statistiques sur les recommandations
  Map<String, dynamic> getLearningStats(List<Destination> allDestinations) {
    if (_interactionHistory.isEmpty) {
      return {
        'totalInteractions': 0,
        'liked': 0,
        'disliked': 0,
        'learningPhase': 'Collecte de données',
      };
    }

    final totalInteractions = _interactionHistory.length;
    final likedCount =
        _interactionHistory.where((i) => i.type == InteractionType.like).length;
    final dislikedCount =
        _interactionHistory
            .where((i) => i.type == InteractionType.dislike)
            .length;

    return {
      'totalInteractions': totalInteractions,
      'liked': likedCount,
      'disliked': dislikedCount,
      'likePercentage':
          '${((likedCount / totalInteractions) * 100).toStringAsFixed(1)}%',
      'learningPhase':
          totalInteractions < 5
              ? 'Collecte de données'
              : totalInteractions < 15
              ? 'Apprentissage actif'
              : 'Recommandations optimisées',
    };
  }

  /// Obtient un résumé textuel des activités et prix pour une destination
  String getDestinationSummary(Destination destination) {
    final activitySummary = _activityAnalyzer.getActivitySummary(
      destination.name,
    );
    final estimatedPrice = _activityAnalyzer.calculateEstimatedPrice(
      destination,
      5,
    );

    return '''
$activitySummary

💰 Prix estimé (5 jours): €${estimatedPrice.toStringAsFixed(2)}
⭐ Note: ${destination.rating}/5
🌍 Climat: ${destination.climate}
''';
  }

  /// Récupère l'historique des interactions
  List<UserInteraction> getInteractionHistory() =>
      List.from(_interactionHistory);
}
