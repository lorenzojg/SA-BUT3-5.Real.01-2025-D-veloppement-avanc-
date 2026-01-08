import 'dart:convert';

/// Modèle de destination basé sur les vraies données de la DB
/// Colonnes DB: id, city, country, region, description, latitude, longitude, 
/// avg_temp_monthly, ideal_durations, budget_level, culture, adventure, nature, 
/// beaches, nightlife, cuisine, wellness, urban, seclusion, input_pays, 
/// input_aeroport, climat_details, hebergement_moyen_eur_nuit, periode_recommandee, 
/// prix_vol_par_mois, tags, prix-moyen-hotel-basse-saison, prix-moyen-hotel-haute-saison,
/// date-basse-saison, date-haute-saison
class DestinationV2 {
  // === Identification ===
  final String id;
  final String city;
  final String country;
  final String region; // 'europe', 'asia', 'africa', etc.
  final String description;
  final double latitude;
  final double longitude;

  // === Climat ===
  /// Températures moyennes par mois {1: {avg, max, min}, ..., 12: {...}}
  final Map<int, Map<String, double>> avgTempMonthly;
  final String climatDetails;
  final String periodeRecommendee;

  // === Budget et Prix ===
  final String budgetLevel; // 'Budget', 'Mid-range', 'Luxury'
  final double hebergementMoyenEurNuit;
  final double? prixMoyenHotelBasseSaison;
  final double? prixMoyenHotelHauteSaison;
  final String? dateBasseSaison;
  final String? dateHauteSaison;
  
  /// Prix des vols par mois [jan, feb, ..., dec]
  final List<double>? prixVolParMois;

  // === Durée ===
  final List<String> idealDurations; // ['Short trip', 'One week', ...]

  // === Scores Vectoriels (0-5) ===
  /// Ces scores sont directement dans la DB et représentent les caractéristiques de la destination
  final double scoreCulture;
  final double scoreAdventure;
  final double scoreNature;
  final double scoreBeaches;
  final double scoreNightlife;
  final double scoreCuisine;
  final double scoreWellness;
  final double scoreUrban;
  final double scoreSeclusion;

  // === Métadonnées ===
  final String inputPays;
  final String inputAeroport;
  final List<String> tags; // Ex: ['Ski', 'Montagne', 'Nature']

  DestinationV2({
    required this.id,
    required this.city,
    required this.country,
    required this.region,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.avgTempMonthly,
    required this.climatDetails,
    required this.periodeRecommendee,
    required this.budgetLevel,
    required this.hebergementMoyenEurNuit,
    this.prixMoyenHotelBasseSaison,
    this.prixMoyenHotelHauteSaison,
    this.dateBasseSaison,
    this.dateHauteSaison,
    this.prixVolParMois,
    required this.idealDurations,
    required this.scoreCulture,
    required this.scoreAdventure,
    required this.scoreNature,
    required this.scoreBeaches,
    required this.scoreNightlife,
    required this.scoreCuisine,
    required this.scoreWellness,
    required this.scoreUrban,
    required this.scoreSeclusion,
    required this.inputPays,
    required this.inputAeroport,
    required this.tags,
  });

  /// Crée une destination depuis une ligne de la DB
  factory DestinationV2.fromDb(Map<String, dynamic> row) {
    // Parse avg_temp_monthly JSON
    Map<int, Map<String, double>> tempMonthly = {};
    try {
      final tempJson = jsonDecode(row['avg_temp_monthly'] as String);
      tempJson.forEach((monthStr, values) {
        final month = int.parse(monthStr);
        tempMonthly[month] = {
          'avg': (values['avg'] as num).toDouble(),
          'max': (values['max'] as num).toDouble(),
          'min': (values['min'] as num).toDouble(),
        };
      });
    } catch (e) {
      print('⚠️ Erreur parsing avg_temp_monthly pour ${row['city']}: $e');
    }

    // Parse prix_vol_par_mois JSON
    List<double>? prixVol;
    try {
      final prixJson = jsonDecode(row['prix_vol_par_mois'] as String);
      prixVol = (prixJson as List).map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      // Pas grave si pas de prix vol
    }

    // Parse ideal_durations JSON
    List<String> durations = [];
    try {
      final durJson = jsonDecode(row['ideal_durations'] as String);
      durations = (durJson as List).map((e) => e.toString()).toList();
    } catch (e) {
      durations = ['One week'];
    }

    // Parse tags JSON
    List<String> tagsList = [];
    try {
      final tagsJson = jsonDecode(row['tags'] as String);
      tagsList = (tagsJson as List).map((e) => e.toString()).toList();
    } catch (e) {
      // Pas grave si pas de tags
    }

    return DestinationV2(
      id: row['id'] as String,
      city: row['city'] as String,
      country: row['country'] as String,
      region: row['region'] as String,
      description: row['description'] as String,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      avgTempMonthly: tempMonthly,
      climatDetails: row['climat_details'] as String? ?? '',
      periodeRecommendee: row['periode_recommandee'] as String? ?? '',
      budgetLevel: row['budget_level'] as String,
      hebergementMoyenEurNuit: (row['hebergement_moyen_eur_nuit'] as num).toDouble(),
      prixMoyenHotelBasseSaison: (row['prix-moyen-hotel-basse-saison'] as num?)?.toDouble(),
      prixMoyenHotelHauteSaison: (row['prix-moyen-hotel-haute-saison'] as num?)?.toDouble(),
      dateBasseSaison: row['date-basse-saison'] as String?,
      dateHauteSaison: row['date-haute-saison'] as String?,
      prixVolParMois: prixVol,
      idealDurations: durations,
      scoreCulture: (row['culture'] as num).toDouble(),
      scoreAdventure: (row['adventure'] as num).toDouble(),
      scoreNature: (row['nature'] as num).toDouble(),
      scoreBeaches: (row['beaches'] as num).toDouble(),
      scoreNightlife: (row['nightlife'] as num).toDouble(),
      scoreCuisine: (row['cuisine'] as num).toDouble(),
      scoreWellness: (row['wellness'] as num).toDouble(),
      scoreUrban: (row['urban'] as num).toDouble(),
      scoreSeclusion: (row['seclusion'] as num).toDouble(),
      inputPays: row['input_pays'] as String? ?? '',
      inputAeroport: row['input_aeroport'] as String? ?? '',
      tags: tagsList,
    );
  }

  // === Méthodes d'analyse ===

  /// Obtient la température moyenne pour un mois donné (1-12)
  double? getAvgTemp(int month) {
    return avgTempMonthly[month]?['avg'];
  }

  /// Obtient la température min pour un mois donné
  double? getMinTemp(int month) {
    return avgTempMonthly[month]?['min'];
  }

  /// Obtient la température max pour un mois donné
  double? getMaxTemp(int month) {
    return avgTempMonthly[month]?['max'];
  }

  /// Obtient le prix du vol pour un mois donné (1-12)
  double? getFlightPrice(int month) {
    if (prixVolParMois == null || month < 1 || month > 12) return null;
    return prixVolParMois![month - 1];
  }

  /// Convertit le budget_level en valeur numérique (0-4)
  double getBudgetLevelNumeric() {
    switch (budgetLevel) {
      case 'Budget':
        return 0.0;
      case 'Mid-range':
        return 2.0;
      case 'Luxury':
        return 4.0;
      default:
        return 2.0;
    }
  }

  /// Calcule un score d'activité basé sur les scores vectoriels (0-100)
  /// Plus le score est élevé, plus la destination est sportive/aventure
  double calculateActivityScore() {
    // Pondération: adventure et nature = sportif, wellness et seclusion = détente
    double sportifScore = (scoreAdventure * 2.0 + scoreNature) / 3.0;
    double detenteScore = (scoreWellness * 2.0 + scoreSeclusion + scoreBeaches) / 4.0;
    
    // Normaliser sur 0-100 (scores DB sont sur 0-5)
    return ((sportifScore - detenteScore + 5) / 10 * 100).clamp(0, 100);
  }

  /// Calcule un score d'urbanité (0-100)
  /// Plus le score est élevé, plus la destination est urbaine
  double calculateUrbanScore() {
    // Pondération: urban et nightlife = ville, nature et seclusion = nature
    double villeScore = (scoreUrban * 2.0 + scoreNightlife) / 3.0;
    double natureScore = (scoreNature * 2.0 + scoreSeclusion) / 3.0;
    
    // Normaliser sur 0-100
    return ((villeScore - natureScore + 5) / 10 * 100).clamp(0, 100);
  }

  /// Vérifie si la destination correspond au continent
  bool matchesContinent(String continent) {
    // Mapping région DB (anglais snake_case) -> continent questionnaire (français)
    final regionLower = region.toLowerCase().replaceAll(' ', '_');
    
    bool matches = false;
    switch (regionLower) {
      case 'europe':
        matches = continent == 'Europe';
        break;
      case 'africa':
        matches = continent == 'Afrique';
        break;
      case 'asia':
        matches = continent == 'Asie';
        break;
      case 'south_america':
        matches = continent == 'Amérique du Sud';
        break;
      case 'north_america':
        matches = continent == 'Amérique du Nord';
        break;
      case 'oceania':
        matches = continent == 'Océanie';
        break;
      default:
        matches = false;
    }
    
    // Debug log pour les 5 premières destinations
    if (id.hashCode % 50 == 0) {
      print('      🔍 Debug: $city ($region) vs "$continent" → $matches');
    }
    
    return matches;
  }

  @override
  String toString() {
    return '📍 $city, $country ($region) - Budget: $budgetLevel';
  }
}
