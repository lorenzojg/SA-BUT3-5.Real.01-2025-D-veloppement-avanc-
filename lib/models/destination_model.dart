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

  // Champs de la logique de recommandation (pour simplifier le Reco Service)
  // Utilise averageCost pour le budget et le score d'activité doit être ajouté
  final double activityScore; // 0.0 (détente) à 100.0 (sportif)

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
    // Laissons l'activityScore comme un champ calculé ou directement dans le JSON
    required this.activityScore, 
  });

  // Méthode fromJson pour le DataLoaderService
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      continent: json['continent'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      activities: List<String>.from(json['activities'] as List),
      averageCost: (json['averageCost'] as num).toDouble(),
      climate: json['climate'] as String,
      duration: (json['duration'] as num).toInt(),
      description: json['description'] as String,
      travelTypes: List<String>.from(json['travelTypes'] as List),
      rating: (json['rating'] as num).toDouble(),
      annualVisitors: (json['annualVisitors'] as num).toDouble(),
      unescoSite: json['unescoSite'] as bool,
      // Supposons que activityScore est aussi dans le JSON
      activityScore: (json['activityScore'] as num? ?? 50.0).toDouble(), 
    );
  }
}