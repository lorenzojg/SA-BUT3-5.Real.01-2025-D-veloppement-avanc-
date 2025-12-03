import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../models/user_interaction_model.dart';
import '../models/user_profile_vector.dart';
import 'activity_analyzer_service.dart';
import 'recommendation_service.dart';
import 'user_interaction_service.dart';
import 'database_service.dart';

export 'activity_analyzer_service.dart' show Activity;

/// Service de recommandation enrichi qui utilise les données d'activités et de prix
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
  late UserProfileVector _currentUserProfile;

  /// Initialise le service avec les préférences de l'utilisateur
  Future<void> initialize({required UserPreferences preferences}) async {
    _basePreferences = preferences;
    _currentUserProfile = RecommendationService.createVectorFromPreferences(preferences);
    // Charger les prix au démarrage (CSV pour l'instant)
    await _activityAnalyzer.loadPrices();
    print('✅ EnhancedRecommendationService initialisé');
  }

  /// Enregistre une interaction utilisateur
  Future<void> recordInteraction(String destinationId, InteractionType type) async {
    _interactionHistory.add(
      UserInteraction(
        destinationId: destinationId,
        type: type,
        timestamp: DateTime.now(),
      ),
    );

    // Mise à jour du vecteur utilisateur
    try {
      final db = DatabaseService();
      final destination = await db.getDestinationById(destinationId);
      if (destination != null) {
        // On crée une interaction temporaire pour la mise à jour du vecteur
        // (On pourrait aussi passer l'objet UserInteraction complet si on l'avait créé avant)
        final interaction = UserInteraction(
          destinationId: destinationId,
          type: type,
          timestamp: DateTime.now(),
          durationMs: 1000, // Valeur par défaut, à affiner si possible
        );
        
        _currentUserProfile = UserInteractionService.updateUserProfile(
          _currentUserProfile,
          destination,
          interaction,
        );
        print('🧠 Vecteur utilisateur mis à jour après interaction ($type)');
        print('   Nature: ${_currentUserProfile.nature.toStringAsFixed(2)}, Culture: ${_currentUserProfile.culture.toStringAsFixed(2)}, Adventure: ${_currentUserProfile.adventure.toStringAsFixed(2)}');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la mise à jour du vecteur utilisateur: $e');
    }
  }

  /// Analyse les préférences apprises depuis les interactions
  Future<Map<String, dynamic>> _analyzeLearnedPreferences(
    List<Destination> allDestinations,
  ) async {
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

    // Analyse des catégories d'activités depuis la DB
    final allActivities = <Activity>[];
    for (final dest in likedDestinations) {
      allActivities.addAll(
        await _activityAnalyzer.getActivitiesForDestination(dest.name),
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
  Future<double> _calculateEnhancedScore(
    Destination destination,
    Map<String, dynamic> learnedPrefs,
  ) async {
    if (learnedPrefs.isEmpty) {
      return 0.0;
    }

    double score = 0.0;

    // 1. Score d'activité basé sur la DB (30 points)
    final enhancedActivityScore = await _activityAnalyzer
        .calculateEnhancedActivityScore(destination, _basePreferences);
    final activityDiff =
        (enhancedActivityScore - (learnedPrefs['avgActivityScore'] as double))
            .abs();
    score += (1 - (activityDiff / 100)).clamp(0, 1) * 30;

    // 2. Score de catégories d'activités (25 points)
    final destActivities = await _activityAnalyzer.getActivitiesForDestination(
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
    
    // Bonus pour les continents sélectionnés initialement (10 points)
    // Permet de ne pas oublier complètement les préférences de base
    if (_basePreferences.selectedContinents.contains(destination.continent)) {
      score += 10;
    }

    // 4. Score de note (15 points)
    score += (destination.rating / 5) * 15;

    // 5. Score de diversité des activités (10 points)
    if (destActivities.length > 5) {
      score += 10;
    }

    // 6. Score de similarité vectorielle (Bonus jusqu'à 20 points)
    // On utilise une méthode simplifiée de similarité ici pour ne pas dépendre de RecommendationService privé
    // On compare les scores de la destination avec le vecteur utilisateur
    double vectorScore = 0.0;
    vectorScore += (1 - (_currentUserProfile.culture - destination.scoreCulture).abs() / 10) * 2;
    vectorScore += (1 - (_currentUserProfile.adventure - destination.scoreAdventure).abs() / 10) * 2;
    vectorScore += (1 - (_currentUserProfile.nature - destination.scoreNature).abs() / 10) * 2;
    // ... on pourrait ajouter toutes les dimensions
    
    score += vectorScore.clamp(0, 20);

    return score.clamp(0, 100);
  }

  /// Recommande les meilleures destinations basées sur l'apprentissage et la DB
  Future<List<Destination>> getEnhancedRecommendations(
    List<Destination> allDestinations, {
    int limit = 10,
  }) async {
    final learnedPrefs = await _analyzeLearnedPreferences(allDestinations);

    // Si peu d'interactions, utiliser les préférences de base
    if (learnedPrefs.isEmpty) {
      return _getBaseRecommendations(allDestinations, limit);
    }

    // Scorer chaque destination
    // Note: On doit utiliser une boucle for ou Future.wait car _calculateEnhancedScore est async
    final scoredDestinations = <Map<String, dynamic>>[];
    
    for (final dest in allDestinations) {
       final score = await _calculateEnhancedScore(dest, learnedPrefs);
       scoredDestinations.add({'destination': dest, 'score': score});
    }

    // Trier par score décroissant
    scoredDestinations.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    return scoredDestinations
        .take(limit)
        .map((item) => item['destination'] as Destination)
        .toList();
  }

  /// Recommandations basées sur les préférences initiales (Cold Start amélioré)
  List<Destination> _getBaseRecommendations(
    List<Destination> allDestinations,
    int limit,
  ) {
    if (_basePreferences.selectedContinents.isEmpty ||
        _basePreferences.activityLevel == null ||
        _basePreferences.budgetLevel == null) {
      return [];
    }

    // Calculer un score pour chaque destination
    final scoredDestinations = allDestinations.map((dest) {
      double score = 0.0;

      // 1. Continent (30 points)
      if (_basePreferences.selectedContinents.contains(dest.continent)) {
        score += 30.0;
      }

      // 2. Budget (30 points)
      final userBudgetLevel = _basePreferences.budgetLevel!.round();
      final destBudgetLevel = _mapCostToBudgetLevel(dest.averageCost);
      
      if (destBudgetLevel <= userBudgetLevel) {
        score += 30.0;
      } else if (destBudgetLevel == userBudgetLevel + 1) {
        // Légèrement au-dessus du budget : pénalité légère mais pas éliminatoire
        score += 10.0;
      } else {
        // Trop cher : pénalité
        score -= 20.0;
      }

      // 3. Niveau d'activité (40 points)
      final diff = (dest.activityScore - _basePreferences.activityLevel!).abs();
      // Plus la différence est petite, plus le score est élevé
      // diff max = 100. Si diff = 0 -> +40. Si diff = 100 -> 0.
      score += (1 - (diff / 100)).clamp(0, 1) * 40;

      return {'destination': dest, 'score': score};
    }).toList();

    // Trier par score décroissant
    scoredDestinations.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Retourner les meilleures
    return scoredDestinations
        .take(limit)
        .map((item) => item['destination'] as Destination)
        .toList();
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
  Future<String> getDestinationSummary(Destination destination) async {
    final activitySummary = await _activityAnalyzer.getActivitySummary(
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
