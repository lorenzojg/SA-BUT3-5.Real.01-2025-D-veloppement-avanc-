import 'dart:convert';

class ActivityModel {
  final String idDestination;       // clé étrangère vers Destination
  final String name;
  final List<String> categories;          // Liste String à partir de json
  final String description;
  final String address;
  final String type;
  final double estimatedPriceEuro;
  final String priceRange;
  final double latitude;
  final double longitude;

  ActivityModel({
    required this.idDestination,
    required this.name,
    required this.categories,
    required this.description,
    required this.address,
    required this.type,
    required this.estimatedPriceEuro,
    required this.priceRange,
    required this.latitude,
    required this.longitude,
  });

  // Conversion depuis SQLite
  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      idDestination: map['id_destination'] as String,
      name: map['name'] as String,
      categories: List<String>.from(jsonDecode(map['categories'] as String)),
      description: map['description'] as String,
      address: map['address'] as String,
      type: map['type'] as String,
      estimatedPriceEuro: (map['estimated_price_euro'] as num).toDouble(),
      priceRange: map['price_range'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}