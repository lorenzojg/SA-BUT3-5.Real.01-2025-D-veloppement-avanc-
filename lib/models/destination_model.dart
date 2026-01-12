import 'dart:convert';

/// Modèle de destination basé sur les vraies données de la DB
/// Colonnes DB: id, city, country, region, description, latitude, longitude, 
/// avg_temp_monthly, ideal_durations, budget_level, culture, adventure, nature, 
/// beaches, nightlife, cuisine, wellness, urban, seclusion, input_pays, 
/// input_aeroport, climat_details, hebergement_moyen_eur_nuit, periode_recommandee, 
/// prix_vol_par_mois, tags, prix-moyen-hotel-basse-saison, prix-moyen-hotel-haute-saison,
/// date-basse-saison, date-haute-saison
class Destination {
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
  final DateTime? dateBasseSaison;
  final DateTime? dateHauteSaison;
  
  /// Prix des vols par mois [jan, feb, ..., dec]
  final List<int>? prixVolParMois;

  // === Durée ===
  final List<String> idealDurations; // ['Short trip', 'One week', ...]

  // === Scores Vectoriels (0-5) ===
  /// Ces scores sont directement dans la DB et représentent les caractéristiques de la destination
  final int scoreCulture;
  final int scoreAdventure;
  final int scoreNature;
  final int scoreBeaches;
  final int scoreNightlife;
  final int scoreCuisine;
  final int scoreWellness;
  final int scoreUrban;
  final int scoreSeclusion;

  // === Métadonnées ===
  final String inputAeroport;
  final List<String> tags; // Ex: ['Ski', 'Montagne', 'Nature']

  Destination({
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
    required this.inputAeroport,
    required this.tags,
  });

  /// Crée une destination depuis une ligne de la DB
  factory Destination.fromMap(Map<String, dynamic> map) {
    // Parse avg_temp_monthly JSON
    Map<int, Map<String, double>> tempMonthly = {};
    try {
      final tempJson = jsonDecode(map['avg_temp_monthly'] as String);
      tempJson.forEach((monthStr, values) {
        final month = int.parse(monthStr);
        tempMonthly[month] = {
          'avg': (values['avg'] as num).toDouble(),
          'max': (values['max'] as num).toDouble(),
          'min': (values['min'] as num).toDouble(),
        };
      });
    } catch (e) {
      print('⚠️ Erreur parsing avg_temp_monthly pour ${map['city']}: $e');
    }

    // Parse prix_vol_par_mois JSON
    List<int>? prixVol;
    try {
      final prixJson = jsonDecode(map['prix_vol_par_mois'] as String);
      prixVol = (prixJson as List).map((e) => (e as int)).toList();
    } catch (e) {
      // Pas grave si pas de prix vol
    }

    // Parse ideal_durations JSON
    List<String> durations = [];
    try {
      final durJson = jsonDecode(map['durees_ideales'] as String);
      durations = (durJson as List).map((e) => e.toString()).toList();
    } catch (e) {
      durations = ['One week'];
    }

    // Parse tags JSON
    List<String> tagsList = [];
    try {
      final tagsJson = jsonDecode(map['tags'] as String);
      tagsList = (tagsJson as List).map((e) => e.toString()).toList();
    } catch (e) {
      // Pas grave si pas de tags
    }


    return Destination(
      id: map['id'] as String,
      city: map['ville'] as String,
      country: map['pays'] as String,
      region: map['region'] as String,
      description: map['description'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      avgTempMonthly: tempMonthly,
      idealDurations: durations,
      budgetLevel: map['budget'] as String,
      scoreCulture: map['culture'] as int,
      scoreAdventure: map['adventure'] as int,
      scoreNature: map['nature'] as int,
      scoreBeaches: map['beaches'] as int,
      scoreNightlife: map['nightlife'] as int,
      scoreCuisine: map['cuisine'] as int,
      scoreWellness: map['wellness'] as int,
      scoreUrban: map['urban'] as int,
      scoreSeclusion: map['seclusion'] as int,
      inputAeroport: map['input_aeroport'] as String? ?? '',
      climatDetails: map['climat_details'] as String? ?? '',
      hebergementMoyenEurNuit: (map['hebergement_moyen_eur_nuit'] as num).toDouble(),
      periodeRecommendee: map['periode_recommandee'] as String? ?? '',
      prixVolParMois: prixVol,
      tags: tagsList,
      prixMoyenHotelBasseSaison: (map['prix-moyen-hotel-basse-saison'] as num?)?.toDouble(),
      prixMoyenHotelHauteSaison: (map['prix-moyen-hotel-haute-saison'] as num?)?.toDouble(),
      dateBasseSaison: DateTime.parse(map['date-basse-saison'] as String),
      dateHauteSaison: DateTime.parse(map['date-haute-saison'] as String),      
    );
  }

  
}
