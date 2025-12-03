class Destination {
  // Champs de la base de données
  final String id;
  final String name;
  final String country;
  final String continent;
  final double latitude;
  final double longitude;
  final List<String> activities;
  final double averageCost; // Coût moyen par jour (DB)
  final String climate;
  final int duration; // Durée idéale en jours
  final String description;
  final List<String> travelTypes;
  final double rating;
  final double annualVisitors;
  final bool unescoSite;

  // Champs de la logique de recommandation (Vectoriel)
  final int activityScore; // 0.0 (détente) à 100.0 (sportif)
  
  // Scores vectoriels (0.0 à 1.0 ou 0 à 5)
  final double scoreCulture;
  final double scoreAdventure;
  final double scoreNature;
  final double scoreBeaches;
  final double scoreNightlife;
  final double scoreCuisine;
  final double scoreWellness;
  final double scoreUrban;
  final double scoreSeclusion;

  // ✅ NOUVEAU : Prix des vols par mois (Jan -> Dec)
  final List<int>? monthlyFlightPrices;

  Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.continent,
    required this.latitude,
    required this.longitude,
    required this.activities,
    required this.averageCost,
    required this.climate,
    required this.duration,
    required this.description,
    required this.travelTypes,
    required this.rating,
    required this.annualVisitors,
    required this.unescoSite,
    required this.activityScore,
    this.scoreCulture = 0.0,
    this.scoreAdventure = 0.0,
    this.scoreNature = 0.0,
    this.scoreBeaches = 0.0,
    this.scoreNightlife = 0.0,
    this.scoreCuisine = 0.0,
    this.scoreWellness = 0.0,
    this.scoreUrban = 0.0,
    this.scoreSeclusion = 0.0,
    this.monthlyFlightPrices,
  });

  // Méthode fromJson pour le DataLoaderService
  factory Destination.fromJson(Map<String, dynamic> json) {
    final activitiesList = List<String>.from(json['activities'] as List);
    
    // Calcul basique des scores si non présents dans le JSON
    // Ceci est une approximation pour faire fonctionner l'algo
    double calcScore(List<String> keywords) {
      int count = 0;
      for (var act in activitiesList) {
        for (var k in keywords) {
          if (act.toLowerCase().contains(k.toLowerCase())) count++;
        }
      }
      return count > 0 ? (count * 1.0).clamp(0.0, 5.0) : 0.0;
    }

    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      continent: json['continent'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      activities: activitiesList,
      averageCost: (json['averageCost'] as num).toDouble(),
      climate: json['climate'] as String,
      duration: (json['duration'] as num).toInt(),
      description: json['description'] as String,
      travelTypes: List<String>.from(json['travelTypes'] as List),
      rating: (json['rating'] as num).toDouble(),
      annualVisitors: (json['annualVisitors'] as num).toDouble(),
      unescoSite: json['unescoSite'] as bool,
      activityScore: (json['activityScore'] as num? ?? 50).toInt(),
      
      // Extraction ou calcul des scores
      scoreCulture: (json['scoreCulture'] as num?)?.toDouble() ?? calcScore(['musée', 'histoire', 'culture', 'art', 'temple']),
      scoreAdventure: (json['scoreAdventure'] as num?)?.toDouble() ?? calcScore(['aventure', 'randonnée', 'trek', 'sport', 'kayak']),
      scoreNature: (json['scoreNature'] as num?)?.toDouble() ?? calcScore(['nature', 'parc', 'montagne', 'forêt', 'paysage']),
      scoreBeaches: (json['scoreBeaches'] as num?)?.toDouble() ?? calcScore(['plage', 'mer', 'sable', 'baignade']),
      scoreNightlife: (json['scoreNightlife'] as num?)?.toDouble() ?? calcScore(['nuit', 'bar', 'club', 'fête', 'soirée']),
      scoreCuisine: (json['scoreCuisine'] as num?)?.toDouble() ?? calcScore(['cuisine', 'gastronomie', 'restaurant', 'manger']),
      scoreWellness: (json['scoreWellness'] as num?)?.toDouble() ?? calcScore(['bien-être', 'spa', 'détente', 'yoga']),
      scoreUrban: (json['scoreUrban'] as num?)?.toDouble() ?? calcScore(['ville', 'shopping', 'urbain', 'architecture']),
      scoreSeclusion: (json['scoreSeclusion'] as num?)?.toDouble() ?? calcScore(['calme', 'isolé', 'tranquille', 'retraite']),
    );
  }
}