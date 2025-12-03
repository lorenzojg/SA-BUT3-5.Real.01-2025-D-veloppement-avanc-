import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../models/activity_model.dart';
import 'database_service.dart';

export '../models/activity_model.dart';

/// Service pour analyser les activités et affiner les recommandations
class ActivityAnalyzerService {
  static final ActivityAnalyzerService _instance =
      ActivityAnalyzerService._internal();

  factory ActivityAnalyzerService() {
    return _instance;
  }

  ActivityAnalyzerService._internal();

  // Cache des prix moyens par pays (on garde ça en mémoire pour l'instant car c'est petit)
  // TODO: Migrer aussi les prix en base si nécessaire
  Map<String, double> _pricesByCountry = {};

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

  /// Obtient les activités pour une destination donnée depuis la DB
  Future<List<Activity>> getActivitiesForDestination(String city) async {
    return await DatabaseService().getActivitiesForDestination(city);
  }

  /// Calcule un score amélioré pour une destination en fonction des activités
  Future<double> calculateEnhancedActivityScore(
    Destination destination,
    UserPreferences preferences,
  ) async {
    final activities = await getActivitiesForDestination(destination.name);

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
    if (preferences.activityLevel != null) {
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
  Future<String> getActivitySummary(String city) async {
    final activities = await getActivitiesForDestination(city);

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
