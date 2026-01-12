import 'dart:math';
import '../models/user_vector_model.dart';

/// Service de calcul de distances vectorielles
/// Utilise la similarité cosinus pour les recommandations
class VectorDistanceService {
  static final VectorDistanceService _instance = VectorDistanceService._internal();
  factory VectorDistanceService() => _instance;
  VectorDistanceService._internal();

  /// Calcule la similarité cosinus entre deux vecteurs
  /// Retourne une valeur entre -1 et 1
  /// 1 = vecteurs identiques, 0 = orthogonaux, -1 = opposés
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have same length: ${a.length} vs ${b.length}');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) {
      return 0.0; // Vecteur nul
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Calcule un score de similarité entre 0 et 100
  /// 100 = match parfait, 0 = opposé
  double similarityScore(List<double> a, List<double> b) {
    final similarity = cosineSimilarity(a, b);
    // Normaliser de [-1, 1] à [0, 100]
    return (similarity + 1.0) * 50.0;
  }

  /// Applique la sérendipité en inversant une composante aléatoire
  /// 
  /// [userVector] Vecteur utilisateur original
  /// [invertContinent] Si true, le continent peut être inversé (recommandé pour mini-jeu)
  /// [continentOnly] Si true, inverse UNIQUEMENT le continent (pour mini-jeu pur)
  /// 
  /// Retourne un vecteur modifié pour découverte
  UserVector applySerendipity(
    UserVector userVector, {
    bool invertContinent = true,
    bool continentOnly = false,
    Random? random,
  }) {
    final rng = random ?? Random();
    
    // Si continentOnly, inverser SEULEMENT le continent
    if (continentOnly) {
      print('🎲 Sérendipité: inversion SEULEMENT du continent (mini-jeu)');
      return _invertContinent(userVector, rng);
    }
    
    // Mode normal: choisir une composante aléatoire
    final components = [
      'temperature',
      'budget',
      'activity',
      'urban',
      'culture',
      'adventure',
      'nature',
    ];
    
    if (invertContinent) {
      components.add('continent');
    }
    
    // Choisir une composante aléatoire
    final chosenComponent = components[rng.nextInt(components.length)];
    
    print('🎲 Sérendipité: inversion de "$chosenComponent"');
    
    // Inverser la composante choisie
    if (chosenComponent == 'continent') {
      return _invertContinent(userVector, rng);
    } else {
      return _invertFeature(userVector, chosenComponent);
    }
  }

  /// Inverse une feature continue (0.3 → 0.7)
  UserVector _invertFeature(UserVector vector, String feature) {
    switch (feature) {
      case 'temperature':
        return vector.copyWith(temperature: 1.0 - vector.temperature);
      case 'budget':
        return vector.copyWith(budget: 1.0 - vector.budget);
      case 'activity':
        return vector.copyWith(activity: 1.0 - vector.activity);
      case 'urban':
        return vector.copyWith(urban: 1.0 - vector.urban);
      case 'culture':
        return vector.copyWith(culture: 1.0 - vector.culture);
      case 'adventure':
        return vector.copyWith(adventure: 1.0 - vector.adventure);
      case 'nature':
        return vector.copyWith(nature: 1.0 - vector.nature);
      default:
        return vector;
    }
  }

  /// Inverse le vecteur continent (choisit des continents différents)
  UserVector _invertContinent(UserVector vector, Random rng) {
    // Créer un vecteur continent inversé (activer les continents non sélectionnés)
    final invertedContinent = vector.continentVector.map((v) => 1.0 - v).toList();
    
    // Si tous sont à 0 maintenant, activer aléatoirement 1-2 continents
    if (invertedContinent.every((v) => v == 0.0)) {
      final numToActivate = rng.nextInt(2) + 1; // 1 ou 2 continents
      for (int i = 0; i < numToActivate; i++) {
        final index = rng.nextInt(6);
        invertedContinent[index] = 1.0;
      }
    }
    
    return vector.copyWith(continentVector: invertedContinent);
  }

  /// Distance euclidienne (alternative, moins utilisée)
  double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have same length');
    }

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }

    return sqrt(sum);
  }

  /// Calcule la distance pondérée avec poids custom par dimension
  /// Utile pour donner plus d'importance à certaines features
  double weightedCosineSimilarity(
    List<double> a,
    List<double> b,
    List<double> weights,
  ) {
    if (a.length != b.length || a.length != weights.length) {
      throw ArgumentError('Vectors and weights must have same length');
    }

    // Appliquer les poids
    final weightedA = List<double>.generate(a.length, (i) => a[i] * weights[i]);
    final weightedB = List<double>.generate(b.length, (i) => b[i] * weights[i]);

    return cosineSimilarity(weightedA, weightedB);
  }
}
