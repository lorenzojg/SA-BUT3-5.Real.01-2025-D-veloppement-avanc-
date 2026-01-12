import 'dart:math';
import '../models/user_vector_model.dart';
import '../models/destination_model.dart';
import 'destination_service.dart';

/// Représente une interaction récente (like/dislike) avec timestamp
class RecentInteraction {
  final Destination destination;
  final String action; // 'like' ou 'dislike'
  final DateTime timestamp;
  
  RecentInteraction({
    required this.destination,
    required this.action,
    required this.timestamp,
  });
  
  /// Calcule le poids de cette interaction basé sur son ancienneté
  /// Plus l'interaction est récente, plus le poids est élevé
  /// Décroissance exponentielle sur 2 minutes
  double getWeight() {
    final now = DateTime.now();
    final ageInMinutes = now.difference(timestamp).inMinutes;
    
    // Décroissance exponentielle: poids max=1.0, half-life=2minutes
    // Formule: w(t) = 2^(-t/halfLife)
    const halfLifeMin = 1.0;
    final weight = pow(2, -ageInMinutes / halfLifeMin);
    
    return weight.toDouble().clamp(0.1, 1.0); // Min 10%, max 100%
  }
}

/// Service de gestion de l'effet de mode court terme
/// Les interactions récentes ont plus d'impact sur le profil utilisateur
class RecentBiasService {
  static final RecentBiasService _instance = RecentBiasService._internal();
  factory RecentBiasService() => _instance;
  RecentBiasService._internal();

  // Historique des interactions récentes (max 20 dernières)
  final List<RecentInteraction> _recentInteractions = [];
  static const int _maxHistory = 20;

  /// Ajoute une interaction récente
  void addInteraction(Destination destination, String action) {
    _recentInteractions.add(RecentInteraction(
      destination: destination,
      action: action,
      timestamp: DateTime.now(),
    ));

    // Garder seulement les N dernières
    if (_recentInteractions.length > _maxHistory) {
      _recentInteractions.removeAt(0);
    }

    print('📝 Interaction ajoutée: $action sur ${destination.city} (${_recentInteractions.length} récentes)');
  }

  /// Calcule les coordonnées moyennes des destinations récemment likées
  /// Retourne {lat, lon} ou null si aucune interaction
  Map<String, double>? getAverageRecentLocation() {
    final recentLikes = _recentInteractions
        .where((i) => i.action == 'like')
        .toList();

    if (recentLikes.isEmpty) return null;

    double totalWeight = 0.0;
    double weightedLat = 0.0;
    double weightedLon = 0.0;

    for (final interaction in recentLikes) {
      final weight = interaction.getWeight();
      weightedLat += interaction.destination.latitude * weight;
      weightedLon += interaction.destination.longitude * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return null;

    return {
      'lat': weightedLat / totalWeight,
      'lon': weightedLon / totalWeight,
    };
  }

  /// Calcule le vecteur utilisateur avec effet de mode court terme
  /// 
  /// [baseVector] Vecteur utilisateur de base
  /// [includeRecentBias] Si true, applique l'effet de mode
  /// 
  /// Formule: finalVector = baseVector * (1-α) + recentVector * α
  /// où α dépend du nombre et de l'ancienneté des interactions
  UserVector applyRecentBias(UserVector baseVector, {bool includeRecentBias = true}) {
    if (!includeRecentBias || _recentInteractions.isEmpty) {
      return baseVector;
    }

    // Filtrer les likes récents (on ignore les dislikes pour le bias positif)
    final recentLikes = _recentInteractions
        .where((i) => i.action == 'like')
        .toList();

    if (recentLikes.isEmpty) {
      return baseVector;
    }

    print('🔥 Application effet de mode: ${recentLikes.length} likes récents');

    // Calculer le vecteur moyen des destinations likées récemment
    // pondéré par l'ancienneté
    final recentVector = _computeWeightedAverageVector(recentLikes);

    // Calculer l'alpha basé sur le nombre et la fraîcheur des interactions
    final alpha = _computeAlpha(recentLikes);

    print('   📊 Alpha (influence récente): ${(alpha * 100).toStringAsFixed(1)}%');

    // Interpoler
    final biasedVector = UserVector.interpolate(baseVector, recentVector, alpha);

    return biasedVector;
  }

  /// Calcule le vecteur moyen pondéré des interactions récentes
  UserVector _computeWeightedAverageVector(List<RecentInteraction> interactions) {
    double totalWeight = 0.0;
    final weightedSum = List<double>.filled(13, 0.0);

    for (final interaction in interactions) {
      final weight = interaction.getWeight();
      final destVector = _destinationToUserVector(interaction.destination);
      final array = destVector.toArray();

      for (int i = 0; i < array.length; i++) {
        weightedSum[i] += array[i] * weight;
      }

      totalWeight += weight;
    }

    // Normaliser par le poids total
    if (totalWeight > 0) {
      for (int i = 0; i < weightedSum.length; i++) {
        weightedSum[i] /= totalWeight;
      }
    }

    return UserVector.fromArray(weightedSum);
  }

  /// Convertit une destination en vecteur (approximation)
  UserVector _destinationToUserVector(Destination dest) {
    // Température du mois actuel
    final currentMonth = DateTime.now().month;
    final currentTemp = DestinationService.getAvgTemp(dest, currentMonth) ?? 20.0; // Valeur par défaut si pas de données

    // Continent vector
    final continentMapping = {
      'europe': [1, 0, 0, 0, 0, 0],
      'africa': [0, 1, 0, 0, 0, 0],
      'asia': [0, 0, 1, 0, 0, 0],
      'north_america': [0, 0, 0, 1, 0, 0],
      'south_america': [0, 0, 0, 0, 1, 0],
      'oceania': [0, 0, 0, 0, 0, 1],
      'middlee_east': [0, 1, 0, 0, 0, 0],
    };

    final continentVector = continentMapping[dest.region.toLowerCase()] ?? 
                            List<double>.filled(6, 0.0);

    return UserVector(
      temperature: UserVector.normalizeTemperature(currentTemp),
      budget: UserVector.normalizeBudget(DestinationService.getBudgetLevelNumeric(dest)),
      activity: DestinationService.calculateActivityScore(dest) / 100.0,
      urban: DestinationService.calculateUrbanScore(dest) / 100.0,
      culture: (dest.scoreCulture / 5.0).clamp(0.0, 1.0),
      adventure: (dest.scoreAdventure / 5.0).clamp(0.0, 1.0),
      nature: (dest.scoreNature / 5.0).clamp(0.0, 1.0),
      continentVector: continentVector.map((v) => v.toDouble()).toList(),
    );
  }

  /// Calcule l'alpha (taux d'apprentissage) basé sur les interactions
  /// Plus les interactions sont récentes et nombreuses, plus alpha est élevé
  double _computeAlpha(List<RecentInteraction> interactions) {
    if (interactions.isEmpty) return 0.0;

    // Poids moyen des interactions
    final avgWeight = interactions
        .map((i) => i.getWeight())
        .reduce((a, b) => a + b) / interactions.length;

    // Base alpha sur le nombre d'interactions et leur fraîcheur
    // 1 interaction très récente: ~15%
    // 5+ interactions récentes: ~40% (réduit de 60% à 40%)
    final countFactor = (interactions.length / 10.0).clamp(0.0, 1.0);
    final timeFactor = avgWeight;

    // Alpha réduit: max 0.4 au lieu de 0.7 pour moins d'influence
    final alpha = (0.1 + countFactor * 0.15 + timeFactor * 0.15).clamp(0.0, 0.4);

    return alpha;
  }

  /// Nettoie les interactions trop anciennes (> 7 minutes)
  void cleanOldInteractions() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 7));
    _recentInteractions.removeWhere((i) => i.timestamp.isBefore(cutoff));
    
    if (_recentInteractions.isNotEmpty) {
      print('🧹 ${_recentInteractions.length} interactions récentes conservées');
    }
  }

  /// Réinitialise l'historique
  void clear() {
    _recentInteractions.clear();
    print('🗑️ Historique d\'interactions effacé');
  }

  /// Récupère le nombre d'interactions récentes
  int get interactionCount => _recentInteractions.length;
}
