import '../models/activity_model.dart';
import '../data/app_database.dart';

/// Service pour gérer la logique métier liée aux activités
/// Sépare du modèle de données
class ActivityService {

  // === Méthodes de scoring (statiques) ===

  /// Calcule un score d'activité (0-100)
  /// Plus c'est élevé, plus c'est sportif/actif
  static double calculateActivityScore(Activity activity) {
    double score = 50.0; // Neutre par défaut

    // Catégories sportives/aventure
    if (activity.categories.contains('aventure') || 
        activity.categories.contains('adventure') ||
        activity.categories.contains('sport')) {
      score += 30.0;
    }
    
    // Catégories nature (modérément actif)
    if (activity.categories.contains('nature') || 
        activity.categories.contains('randonnée')) {
      score += 15.0;
    }

    // Catégories détente
    if (activity.categories.contains('bien-être') || 
        activity.categories.contains('wellness') ||
        activity.categories.contains('plages')) {
      score -= 15.0;
    }

    // Catégories culture (légèrement actif)
    if (activity.categories.contains('culture') || 
        activity.categories.contains('urbain')) {
      score += 5.0;
    }

    return score.clamp(0, 100);
  }

  /// Calcule un score d'urbanité (0-100)
  /// Plus c'est élevé, plus c'est urbain
  static double calculateUrbanScore(Activity activity) {
    double score = 50.0;

    // Urbain
    if (activity.categories.contains('urbain') || 
        activity.categories.contains('culture') ||
        activity.categories.contains('vie nocturne')) {
      score += 30.0;
    }

    // Nature
    if (activity.categories.contains('nature') || 
        activity.categories.contains('plages')) {
      score -= 30.0;
    }

    return score.clamp(0, 100);
  }

  /// Retourne le prix numérique basé sur le price_range
  static double getPriceLevel(Activity activity) {
    switch (activity.priceRange) {
      case 'Gratuit':
        return 0.0;
      case '€':
        return 1.0;
      case '€€':
        return 2.0;
      case '€€€':
        return 3.0;
      case '€€€€':
        return 4.0;
      default:
        return activity.estimatedPriceEuro;
    }
  }

  /// Vérifie si l'activité correspond à un niveau d'activité utilisateur (0-100)
  static bool matchesActivityLevel(Activity activity, double userActivityLevel) {
    final activityScore = calculateActivityScore(activity);
    // Tolérance de ±25 points
    return (activityScore - userActivityLevel).abs() <= 25.0;
  }

  /// Vérifie si l'activité correspond à une préférence urbain/nature (0-100)
  static bool matchesUrbanLevel(Activity activity, double userUrbanLevel) {
    final urbanScore = calculateUrbanScore(activity);
    // Tolérance de ±25 points
    return (urbanScore - userUrbanLevel).abs() <= 25.0;
  }

  /// Convertit une activité en chaîne de caractères
  static String activityToString(Activity activity) {
    return '🎯 ${activity.name} (${activity.type}) - ${activity.priceRange.isEmpty ? 'Prix inconnu' : activity.priceRange}';
  }

  /// Récupère les activités pour une destination
  Future<List<Activity>> getActivitiesForDestination(String destinationId) async {
  final db = await AppDatabase().database;
  
  try {
    
    
    final List<Map<String, dynamic>> maps = await db.query(
     'Activite',
      where: 'id_destination = ?',
      whereArgs: [destinationId],
    );    
    return maps.map((row) => Activity.fromMap(row)).toList();
  } catch (e) {
    print('❌ Erreur lecture activités pour destination $destinationId: $e');
    return [];
  }
}

  /// Compte le nombre d'activités
  Future<int> getActivitiesCount() async {
    // Methode à écrir ici directement dans cette classe
    final db = await AppDatabase().database;
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM Activite');
      final count = result.first['count'] as int?;
      return count ?? 0;
    } catch (e) {
      print('❌ Erreur comptage activités: $e');
      return 0;
    }
  }
}
