import 'dart:convert';

/// Modèle pour représenter une activité
class Activity {
  final String name;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final List<String> categories;
  final double rating;
  final bool hasFee;
  final bool hasWheelchair;

  Activity({
    required this.name,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.rating,
    required this.hasFee,
    required this.hasWheelchair,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'categories': jsonEncode(categories),
      'rating': rating,
      'hasFee': hasFee ? 1 : 0,
      'hasWheelchair': hasWheelchair ? 1 : 0,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      name: map['name'] as String,
      city: map['city'] as String,
      country: map['country'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      categories: List<String>.from(jsonDecode(map['categories'] as String)),
      rating: (map['rating'] as num).toDouble(),
      hasFee: (map['hasFee'] as int) == 1,
      hasWheelchair: (map['hasWheelchair'] as int) == 1,
    );
  }

  /// Calcule un score d'activité basé sur les catégories (0-100)
  int calculateActivityScore() {
    int score = 50; // Score de base neutre

    // Ajuster selon les catégories d'activité
    if (categories.contains('adventure') || categories.contains('sport')) {
      score += 30; // Sportif
    } else if (categories.contains('nature') ||
        categories.contains('leisure')) {
      score += 10; // Plutôt détente
    } else if (categories.contains('culture') || categories.contains('urban')) {
      score += 5; // Légèrement plus actif (musées, exploration urbaine)
    } else if (categories.contains('nightlife') ||
        categories.contains('cuisine')) {
      score -= 5; // Plutôt détente
    }

    // Bonus pour les activités bien notées
    if (rating > 0) {
      score += (rating * 5).toInt().clamp(0, 10);
    }

    return score.clamp(0, 100);
  }

  /// Retourne les catégories principales (pour matching)
  List<String> getPrimaryCategories() {
    return categories
        .where(
          (cat) =>
              !cat.contains('.') &&
              [
                'adventure',
                'sport',
                'nature',
                'culture',
                'urban',
                'nightlife',
                'cuisine',
                'leisure',
              ].contains(cat),
        )
        .toList();
  }
}
