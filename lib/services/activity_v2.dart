import 'dart:convert';

/// Modèle d'activité basé sur les vraies données de la DB
/// Colonnes DB: id_destination, name, categories, description, address, type, 
/// estimated_price_euro, price_range, latitude, longitude
class ActivityV2 {
  final String idDestination;
  final String name;
  final List<String> categories; // Ex: ['culture', 'urbain']
  final String description;
  final String address;
  final String type; // Ex: 'Cathédrale', 'Musée', 'Plage'
  final double? estimatedPriceEuro;
  final String priceRange; // 'Gratuit', '€', '€€', '€€€', '€€€€'
  final double latitude;
  final double longitude;

  ActivityV2({
    required this.idDestination,
    required this.name,
    required this.categories,
    required this.description,
    required this.address,
    required this.type,
    this.estimatedPriceEuro,
    required this.priceRange,
    required this.latitude,
    required this.longitude,
  });

  /// Crée une activité depuis une ligne de la DB
  factory ActivityV2.fromMap(Map<String, dynamic> row) {
    // Parse categories JSON
    List<String> cats = [];
    try {
      final catsJson = jsonDecode(row['categories'] as String);
      cats = (catsJson as List).map((e) => e.toString()).toList();
    } catch (e) {
      print('⚠️ Erreur parsing categories pour ${row['name']}: $e');
    }

    return ActivityV2(
      idDestination: row['id_destination'] as String,
      name: row['name'] as String,
      categories: cats,
      description: row['description'] as String? ?? '',
      address: row['address'] as String? ?? '',
      type: row['type'] as String? ?? '',
      estimatedPriceEuro: (row['estimated_price_euro'] as num?)?.toDouble(),
      priceRange: row['price_range'] as String? ?? '',
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
    );
  }

  /// Convertit en Map pour l'insertion en DB
  Map<String, dynamic> toDb() {
    return {
      'id_destination': idDestination,
      'name': name,
      'categories': jsonEncode(categories),
      'description': description,
      'address': address,
      'type': type,
      'estimated_price_euro': estimatedPriceEuro,
      'price_range': priceRange,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // === Méthodes de scoring ===

  /// Calcule un score d'activité (0-100)
  /// Plus c'est élevé, plus c'est sportif/actif
  double calculateActivityScore() {
    double score = 50.0; // Neutre par défaut

    // Catégories sportives/aventure
    if (categories.contains('aventure') || 
        categories.contains('adventure') ||
        categories.contains('sport')) {
      score += 30.0;
    }
    
    // Catégories nature (modérément actif)
    if (categories.contains('nature') || 
        categories.contains('randonnée')) {
      score += 15.0;
    }

    // Catégories détente
    if (categories.contains('bien-être') || 
        categories.contains('wellness') ||
        categories.contains('plages')) {
      score -= 15.0;
    }

    // Catégories culture (légèrement actif)
    if (categories.contains('culture') || 
        categories.contains('urbain')) {
      score += 5.0;
    }

    return score.clamp(0, 100);
  }

  /// Calcule un score d'urbanité (0-100)
  /// Plus c'est élevé, plus c'est urbain
  double calculateUrbanScore() {
    double score = 50.0;

    // Urbain
    if (categories.contains('urbain') || 
        categories.contains('culture') ||
        categories.contains('vie nocturne')) {
      score += 30.0;
    }

    // Nature
    if (categories.contains('nature') || 
        categories.contains('plages')) {
      score -= 30.0;
    }

    return score.clamp(0, 100);
  }

  /// Retourne le prix numérique basé sur le price_range
  double getPriceLevel() {
    switch (priceRange) {
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
        return estimatedPriceEuro ?? 0.0;
    }
  }

  /// Vérifie si l'activité correspond à un niveau d'activité utilisateur (0-100)
  bool matchesActivityLevel(double userActivityLevel) {
    final activityScore = calculateActivityScore();
    // Tolérance de ±25 points
    return (activityScore - userActivityLevel).abs() <= 25.0;
  }

  /// Vérifie si l'activité correspond à une préférence urbain/nature (0-100)
  bool matchesUrbanLevel(double userUrbanLevel) {
    final urbanScore = calculateUrbanScore();
    // Tolérance de ±25 points
    return (urbanScore - userUrbanLevel).abs() <= 25.0;
  }

  @override
  String toString() {
    return '🎯 $name ($type) - ${priceRange.isEmpty ? 'Prix inconnu' : priceRange}';
  }
}
