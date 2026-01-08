import '../models/user_preferences_v2.dart';
import '../models/destination_v2.dart';

/// Service pour mettre à jour les préférences utilisateur basé sur les interactions
/// Utilisé après le mini-jeu like/dislike pour affiner les recommandations
class UserLearningService {
  static final UserLearningService _instance = UserLearningService._internal();
  factory UserLearningService() => _instance;
  UserLearningService._internal();

  /// Met à jour les préférences après une série de likes/dislikes
  /// 
  /// [currentPrefs] Préférences actuelles
  /// [likedDestinations] Destinations likées
  /// [dislikedDestinations] Destinations dislikées
  /// 
  /// Retourne les nouvelles préférences mises à jour
  UserPreferencesV2 updatePreferencesFromInteractions({
    required UserPreferencesV2 currentPrefs,
    required List<DestinationV2> likedDestinations,
    required List<DestinationV2> dislikedDestinations,
  }) {
    print('🧠 Apprentissage à partir de ${likedDestinations.length} likes et ${dislikedDestinations.length} dislikes');

    // Si pas assez d'interactions, retourner les préférences inchangées
    if (likedDestinations.isEmpty && dislikedDestinations.isEmpty) {
      return currentPrefs;
    }

    // === 1. Mise à jour du niveau d'activité ===
    final newActivityLevel = _learnActivityLevel(
      currentPrefs.activityLevel,
      likedDestinations,
      dislikedDestinations,
    );

    // === 2. Mise à jour de la préférence urbain/nature ===
    final newUrbanLevel = _learnUrbanLevel(
      currentPrefs.urbanLevel,
      likedDestinations,
      dislikedDestinations,
    );

    // === 3. Mise à jour de la température préférée ===
    final newMinTemperature = _learnTemperaturePreference(
      currentPrefs.minTemperature,
      currentPrefs.travelMonth,
      likedDestinations,
      dislikedDestinations,
    );

    // === 4. Mise à jour du budget (optionnel) ===
    final newBudgetLevel = _learnBudgetPreference(
      currentPrefs.budgetLevel,
      likedDestinations,
      dislikedDestinations,
    );

    // === 5. Mise à jour des continents (ajout de préférences) ===
    final newContinents = _learnContinentPreferences(
      currentPrefs.selectedContinents,
      likedDestinations,
    );

    print('📊 Mise à jour:');
    print('   Activité: ${currentPrefs.activityLevel.toStringAsFixed(1)} → ${newActivityLevel.toStringAsFixed(1)}');
    print('   Urbain: ${currentPrefs.urbanLevel.toStringAsFixed(1)} → ${newUrbanLevel.toStringAsFixed(1)}');
    print('   Temp: ${currentPrefs.minTemperature.toStringAsFixed(1)} → ${newMinTemperature.toStringAsFixed(1)}°C');
    print('   Budget: ${currentPrefs.budgetLevel.toStringAsFixed(1)} → ${newBudgetLevel.toStringAsFixed(1)}');
    print('   Continents: ${currentPrefs.selectedContinents.join(", ")} → ${newContinents.join(", ")}');

    return currentPrefs.copyWith(
      activityLevel: newActivityLevel,
      urbanLevel: newUrbanLevel,
      minTemperature: newMinTemperature,
      budgetLevel: newBudgetLevel,
      selectedContinents: newContinents,
    );
  }

  /// Apprend le niveau d'activité préféré
  double _learnActivityLevel(
    double currentLevel,
    List<DestinationV2> liked,
    List<DestinationV2> disliked,
  ) {
    if (liked.isEmpty && disliked.isEmpty) return currentLevel;

    // Calculer la moyenne des niveaux d'activité des destinations likées
    double likedAvg = 0.0;
    if (liked.isNotEmpty) {
      likedAvg = liked.map((d) => d.calculateActivityScore()).reduce((a, b) => a + b) / liked.length;
    }

    // Calculer la moyenne des niveaux d'activité des destinations dislikées
    double dislikedAvg = 0.0;
    if (disliked.isNotEmpty) {
      dislikedAvg = disliked.map((d) => d.calculateActivityScore()).reduce((a, b) => a + b) / disliked.length;
    }

    // Taux d'apprentissage: plus on a d'interactions, plus on ajuste
    final learningRate = _calculateLearningRate(liked.length + disliked.length);

    // Nouvelle valeur: moyenne pondérée entre l'actuel et les préférences observées
    double targetLevel = currentLevel;
    
    if (liked.isNotEmpty && disliked.isEmpty) {
      // Seulement des likes: on se rapproche de la moyenne likée
      targetLevel = currentLevel + (likedAvg - currentLevel) * learningRate;
    } else if (disliked.isNotEmpty && liked.isEmpty) {
      // Seulement des dislikes: on s'éloigne de la moyenne dislikée
      targetLevel = currentLevel - (dislikedAvg - currentLevel) * learningRate * 0.5;
    } else if (liked.isNotEmpty && disliked.isNotEmpty) {
      // Les deux: on favorise les likes et on s'éloigne des dislikes
      final targetFromLikes = likedAvg;
      final targetFromDislikes = currentLevel - (dislikedAvg - currentLevel) * 0.3;
      targetLevel = (targetFromLikes * 0.7 + targetFromDislikes * 0.3);
      targetLevel = currentLevel + (targetLevel - currentLevel) * learningRate;
    }

    return targetLevel.clamp(0, 100);
  }

  /// Apprend la préférence urbain/nature
  double _learnUrbanLevel(
    double currentLevel,
    List<DestinationV2> liked,
    List<DestinationV2> disliked,
  ) {
    if (liked.isEmpty && disliked.isEmpty) return currentLevel;

    double likedAvg = 0.0;
    if (liked.isNotEmpty) {
      likedAvg = liked.map((d) => d.calculateUrbanScore()).reduce((a, b) => a + b) / liked.length;
    }

    double dislikedAvg = 0.0;
    if (disliked.isNotEmpty) {
      dislikedAvg = disliked.map((d) => d.calculateUrbanScore()).reduce((a, b) => a + b) / disliked.length;
    }

    final learningRate = _calculateLearningRate(liked.length + disliked.length);
    double targetLevel = currentLevel;

    if (liked.isNotEmpty && disliked.isEmpty) {
      targetLevel = currentLevel + (likedAvg - currentLevel) * learningRate;
    } else if (disliked.isNotEmpty && liked.isEmpty) {
      targetLevel = currentLevel - (dislikedAvg - currentLevel) * learningRate * 0.5;
    } else if (liked.isNotEmpty && disliked.isNotEmpty) {
      final targetFromLikes = likedAvg;
      final targetFromDislikes = currentLevel - (dislikedAvg - currentLevel) * 0.3;
      targetLevel = (targetFromLikes * 0.7 + targetFromDislikes * 0.3);
      targetLevel = currentLevel + (targetLevel - currentLevel) * learningRate;
    }

    return targetLevel.clamp(0, 100);
  }

  /// Apprend la préférence de température
  double _learnTemperaturePreference(
    double currentMinTemp,
    int? travelMonth,
    List<DestinationV2> liked,
    List<DestinationV2> disliked,
  ) {
    if (liked.isEmpty) return currentMinTemp;

    final month = travelMonth ?? DateTime.now().month;
    
    // Extraire les températures des destinations likées
    final likedTemps = <double>[];
    for (final dest in liked) {
      final temp = dest.getAvgTemp(month);
      if (temp != null) likedTemps.add(temp);
    }

    if (likedTemps.isEmpty) return currentMinTemp;

    // Calculer la température moyenne des destinations likées
    final avgLikedTemp = likedTemps.reduce((a, b) => a + b) / likedTemps.length;

    // Ajuster la température minimale (légèrement en dessous de la moyenne likée)
    final targetMinTemp = avgLikedTemp - 3.0; // 3°C en dessous pour la tolérance

    final learningRate = _calculateLearningRate(liked.length);
    final newMinTemp = currentMinTemp + (targetMinTemp - currentMinTemp) * learningRate;

    return newMinTemp.clamp(0, 40);
  }

  /// Apprend la préférence de budget
  double _learnBudgetPreference(
    double currentBudget,
    List<DestinationV2> liked,
    List<DestinationV2> disliked,
  ) {
    if (liked.isEmpty) return currentBudget;

    // Extraire les niveaux de budget des destinations likées
    final likedBudgets = liked.map((d) => d.getBudgetLevelNumeric()).toList();
    final avgLikedBudget = likedBudgets.reduce((a, b) => a + b) / likedBudgets.length;

    final learningRate = _calculateLearningRate(liked.length) * 0.5; // Moins agressif pour le budget
    final newBudget = currentBudget + (avgLikedBudget - currentBudget) * learningRate;

    return newBudget.clamp(0, 4);
  }

  /// Apprend les continents préférés
  List<String> _learnContinentPreferences(
    List<String> currentContinents,
    List<DestinationV2> liked,
  ) {
    if (liked.isEmpty) return currentContinents;

    // Compter les continents des destinations likées
    final continentCount = <String, int>{};
    for (final dest in liked) {
      final mapping = {
        'europe': 'Europe',
        'africa': 'Afrique',
        'asia': 'Asie',
        'south_america': 'Amérique du Sud',
        'north_america': 'Amérique du Nord',
        'oceania': 'Océanie',
        'antarctica': 'Antarctique',
      };
      
      final continent = mapping[dest.region.toLowerCase()];
      if (continent != null) {
        continentCount[continent] = (continentCount[continent] ?? 0) + 1;
      }
    }

    // Ajouter les continents populaires (> 20% des likes)
    final newContinents = List<String>.from(currentContinents);
    final threshold = liked.length * 0.2;
    
    continentCount.forEach((continent, count) {
      if (count >= threshold && !newContinents.contains(continent)) {
        print('🌍 Ajout du continent "$continent" (${count}/${liked.length} likes)');
        newContinents.add(continent);
      }
    });

    return newContinents;
  }

  /// Calcule le taux d'apprentissage basé sur le nombre d'interactions
  /// Plus il y a d'interactions, plus on ajuste fort (mais avec un plafond)
  double _calculateLearningRate(int interactionCount) {
    if (interactionCount <= 3) {
      return 0.1; // Peu d'interactions: ajustement léger
    } else if (interactionCount <= 5) {
      return 0.2; // Interactions moyennes
    } else if (interactionCount <= 10) {
      return 0.3; // Beaucoup d'interactions
    } else {
      return 0.4; // Très confiant
    }
  }

  /// Mise à jour incrémentale après une seule interaction (pour le temps réel)
  /// Utilisé quand l'utilisateur like/dislike une destination individuellement
  UserPreferencesV2 updateFromSingleInteraction({
    required UserPreferencesV2 currentPrefs,
    required DestinationV2 destination,
    required bool isLike,
  }) {
    // Learning rate faible pour une seule interaction
    const learningRate = 0.05;

    if (isLike) {
      // Ajuster vers les caractéristiques de la destination
      final destActivity = destination.calculateActivityScore();
      final destUrban = destination.calculateUrbanScore();
      final month = currentPrefs.travelMonth ?? DateTime.now().month;
      final destTemp = destination.getAvgTemp(month);

      return currentPrefs.copyWith(
        activityLevel: currentPrefs.activityLevel + (destActivity - currentPrefs.activityLevel) * learningRate,
        urbanLevel: currentPrefs.urbanLevel + (destUrban - currentPrefs.urbanLevel) * learningRate,
        minTemperature: destTemp != null 
            ? currentPrefs.minTemperature + (destTemp - 3.0 - currentPrefs.minTemperature) * learningRate
            : currentPrefs.minTemperature,
      );
    } else {
      // Dislike: s'éloigner légèrement des caractéristiques
      final destActivity = destination.calculateActivityScore();
      final destUrban = destination.calculateUrbanScore();

      return currentPrefs.copyWith(
        activityLevel: currentPrefs.activityLevel - (destActivity - currentPrefs.activityLevel) * learningRate * 0.5,
        urbanLevel: currentPrefs.urbanLevel - (destUrban - currentPrefs.urbanLevel) * learningRate * 0.5,
      );
    }
  }
}
