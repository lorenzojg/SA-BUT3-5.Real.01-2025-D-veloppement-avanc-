// lib/models/destination_model.dart

class Destination {
  final String id;
  final String name;
  final String country;
  final String continent;          // ✅ Nouveau - Europe, Asie, Afrique, etc.
  final double latitude;
  final double longitude;
  final List<String> activities;   // ['randonnée', 'plage', 'musée']
  final double averageCost;        // en USD par jour
  final String climate;            // 'ensoleillé', 'pluvieux', etc.
  final int duration;              // durée idéale en jours
  final String description;
  final List<String> travelTypes;  // ✅ Nouveau - ['solo', 'couple', 'famille']
  final double rating;             // ✅ Nouveau - Note moyenne (0-5)
  final double annualVisitors;     // ✅ Nouveau - Visiteurs annuels (en millions)
  final bool unescoSite;           // ✅ Nouveau - Site UNESCO ou non

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
  });

  // Convertir depuis JSON (important pour charger les données embarquées)
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      country: json['country'] ?? 'Unknown',
      continent: json['continent'] ?? 'Unknown',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      activities: json['activities'] != null
          ? List<String>.from(json['activities'])
          : ['culture'],
      averageCost: (json['averageCost'] ?? 0.0).toDouble(),
      climate: json['climate'] ?? 'tempéré',
      duration: json['duration'] ?? 3,
      description: json['description'] ?? '',
      travelTypes: json['travelTypes'] != null
          ? List<String>.from(json['travelTypes'])
          : ['solo', 'couple', 'famille'],
      rating: (json['rating'] ?? 4.0).toDouble(),
      annualVisitors: (json['annualVisitors'] ?? 1.0).toDouble(),
      unescoSite: json['unescoSite'] ?? false,
    );
  }

  // Convertir vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'continent': continent,
      'latitude': latitude,
      'longitude': longitude,
      'activities': activities,
      'averageCost': averageCost,
      'climate': climate,
      'duration': duration,
      'description': description,
      'travelTypes': travelTypes,
      'rating': rating,
      'annualVisitors': annualVisitors,
      'unescoSite': unescoSite,
    };
  }

  // Helper pour afficher les informations de la destination
  @override
  String toString() {
    return 'Destination{name: $name, country: $country, continent: $continent, cost: \$$averageCost, rating: $rating}';
  }

  // Helper pour vérifier si la destination correspond à un budget
  bool matchesBudget(double maxBudget) {
    return averageCost <= maxBudget;
  }

  // Helper pour vérifier si la destination correspond à un continent
  bool matchesContinent(String targetContinent) {
    return continent.toLowerCase() == targetContinent.toLowerCase();
  }

  // Helper pour vérifier si la destination correspond à un type de voyage
  bool matchesTravelType(String travelType) {
    return travelTypes.contains(travelType.toLowerCase());
  }
}
