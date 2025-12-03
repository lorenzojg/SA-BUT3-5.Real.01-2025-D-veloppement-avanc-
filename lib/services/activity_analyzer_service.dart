import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';

/// Modèle pour représenter une activité du CSV
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

/// Service pour analyser les activités CSV et affiner les recommandations
class ActivityAnalyzerService {
  static final ActivityAnalyzerService _instance =
      ActivityAnalyzerService._internal();

  factory ActivityAnalyzerService() {
    return _instance;
  }

  ActivityAnalyzerService._internal();

  // Cache des activités par destination
  Map<String, List<Activity>> _activitiesByDestination = {};

  // Cache des prix moyens par pays
  Map<String, double> _pricesByCountry = {};

  /// Charge les activités depuis le CSV
  Future<void> loadActivities() async {
    try {
      final csvString = await rootBundle.loadString(
        'assets/data/activities.csv',
      );
      final lines = csvString.split('\n');

      for (int i = 1; i < lines.length; i++) {
        // Sauter l'en-tête et ignorer les lignes vides
        if (lines[i].trim().isEmpty) continue;

        try {
          final activity = _parseActivityLine(lines[i]);
          if (activity != null) {
            final destination = activity.city; // Utiliser la ville comme clé
            if (!_activitiesByDestination.containsKey(destination)) {
              _activitiesByDestination[destination] = [];
            }
            _activitiesByDestination[destination]!.add(activity);
          }
        } catch (e) {
          // Ignorer les lignes mal formatées
          print('⚠️ Erreur parsing activité ligne $i: $e');
        }
      }

      print(
        '✅ ${_activitiesByDestination.length} destinations d\'activités chargées',
      );
      for (final entry in _activitiesByDestination.entries) {
        print('   - ${entry.key}: ${entry.value.length} activités');
      }
    } catch (e) {
      print('❌ Erreur chargement activités: $e');
    }
  }

  /// Parse une ligne CSV d'activité (format complexe avec JSON imbriqué)
  Activity? _parseActivityLine(String line) {
    try {
      // Approche robuste : parser avec gestion des guillemets
      final fields = _parseCSVLine(line);

      if (fields.length < 14) return null;

      // Extraction des champs
      final categoriesJson = fields[1];
      final city = fields[2];
      final country = fields[3];
      final latitude = double.tryParse(fields[9]) ?? 0.0;
      final longitude = double.tryParse(fields[10]) ?? 0.0;
      final name = fields[11];
      final rating = double.tryParse(fields[12]) ?? 0.0;
      final typesJson = fields[13];

      // Parser les catégories (format: ["cat1", "cat2"])
      final categories = _parseJsonArray(categoriesJson);

      // Parser les types pour extraire des infos
      final types = _parseJsonArray(typesJson);
      final hasFee = types.contains('fee');
      final hasWheelchair =
          types.contains('wheelchair') && types.contains('wheelchair.yes');

      return Activity(
        name: name,
        city: city,
        country: country,
        latitude: latitude,
        longitude: longitude,
        categories: categories,
        rating: rating,
        hasFee: hasFee,
        hasWheelchair: hasWheelchair,
      );
    } catch (e) {
      print('Erreur parsing: $e');
      return null;
    }
  }

  /// Parse une ligne CSV en respectant les guillemets
  List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(current.replaceAll('"', '').trim());
        current = '';
      } else {
        current += char;
      }
    }

    fields.add(current.replaceAll('"', '').trim());
    return fields;
  }

  /// Parse un tableau JSON imbriqué dans le CSV
  List<String> _parseJsonArray(String jsonString) {
    try {
      final cleaned = jsonString.replaceAll('""', '"').trim();
      if (!cleaned.startsWith('[')) return [];

      final list = jsonDecode(cleaned) as List;
      return list.map((e) => e.toString().toLowerCase()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Charge les prix moyens par pays
  Future<void> loadPrices() async {
    try {
      final csvString = await rootBundle.loadString(
        'assets/data/prixMoyens.csv',
      );
      final lines = csvString.split('\n');

      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;

        final fields = lines[i].split(',');
        if (fields.length >= 3) {
          final country = fields[1].trim();
          final cost = double.tryParse(fields[3].trim());

          if (cost != null) {
            _pricesByCountry[country] = cost;
          }
        }
      }

      print('✅ Données de prix chargées pour ${_pricesByCountry.length} pays');
    } catch (e) {
      print('❌ Erreur chargement prix: $e');
    }
  }

  /// Obtient les activités pour une destination donnée
  List<Activity> getActivitiesForDestination(String city) {
    return _activitiesByDestination[city] ?? [];
  }

  /// Calcule un score amélioré pour une destination en fonction des activités
  double calculateEnhancedActivityScore(
    Destination destination,
    UserPreferences preferences,
  ) {
    final activities = getActivitiesForDestination(destination.name);

    if (activities.isEmpty) {
      // Retourner le score original si pas d'activités détaillées
      return destination.activityScore.toDouble();
    }

    // Analyser les catégories des activités
    final allCategories = <String, int>{};
    final activityScores = <int>[];

    for (final activity in activities) {
      final score = activity.calculateActivityScore();
      activityScores.add(score);

      for (final cat in activity.getPrimaryCategories()) {
        allCategories[cat] = (allCategories[cat] ?? 0) + 1;
      }
    }

    // Score moyen des activités
    final avgActivityScore =
        activityScores.isNotEmpty
            ? activityScores.reduce((a, b) => a + b) / activityScores.length
            : destination.activityScore.toDouble();

    // Calcul du matching entre les catégories d'activités et les préférences
    double categoryMatch = 0.0;
    if (preferences.activityLevel! > 70) {
      // L'utilisateur préfère les activités sportives
      if (allCategories.containsKey('adventure') ||
          allCategories.containsKey('sport')) {
        categoryMatch = 20.0; // Bonus
      }
    } else if (preferences.activityLevel! < 30) {
      // L'utilisateur préfère la détente
      if (allCategories.containsKey('nature') ||
          allCategories.containsKey('leisure')) {
        categoryMatch = 20.0; // Bonus
      }
    } else {
      // Utilisateur équilibré : récompenser la diversité
      if (allCategories.length > 3) {
        categoryMatch = 10.0;
      }
    }

    // Score amélioré : moyenne pondérée
    return (avgActivityScore + categoryMatch).clamp(0, 100);
  }

  /// Calcule le prix final estimé pour un voyage
  double calculateEstimatedPrice(Destination destination, int daysCount) {
    final basePrice = destination.averageCost;
    final countryPrice = _pricesByCountry[destination.country];

    if (countryPrice == null) {
      return basePrice * daysCount;
    }

    // Combiner le prix de la destination avec le prix moyen du pays
    final blendedPrice = (basePrice + countryPrice) / 2;
    return blendedPrice * daysCount;
  }

  /// Génère un texte descriptif des activités principales pour une destination
  String getActivitySummary(String city) {
    final activities = getActivitiesForDestination(city);

    if (activities.isEmpty) {
      return 'Aucune activité détaillée disponible.';
    }

    // Compter les catégories
    final categories = <String, int>{};
    for (final activity in activities) {
      for (final cat in activity.getPrimaryCategories()) {
        categories[cat] = (categories[cat] ?? 0) + 1;
      }
    }

    // Trier par fréquence et formater
    final sorted =
        categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final summary = sorted
        .take(3)
        .map((e) => '${e.key} (${e.value} activités)')
        .join(', ');

    return 'Principales activités: $summary. Total: ${activities.length} activités répertoriées.';
  }
}
