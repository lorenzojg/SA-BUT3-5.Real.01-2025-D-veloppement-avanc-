/// Vecteur destination pour recommandations vectorielles
/// Dimension : 13 (7 features + 6 continents)
class DestinationVector {
  final String destinationId;
  
  // Features continues (normalisées 0-1)
  final double temperature;   // Température moyenne normalisée
  final double budget;         // Budget normalisé
  final double activity;       // Niveau d'activité de la destination
  final double urban;          // Score urbain de la destination
  final double culture;        // Score culture
  final double adventure;      // Score aventure
  final double nature;         // Score nature
  
  // Continent (one-hot encoding)
  final List<double> continentVector;
  
  DestinationVector({
    required this.destinationId,
    required this.temperature,
    required this.budget,
    required this.activity,
    required this.urban,
    required this.culture,
    required this.adventure,
    required this.nature,
    required this.continentVector,
  });
  
  /// Convertit en array pour calculs de distance
  List<double> toArray() {
    return [
      temperature,
      budget,
      activity,
      urban,
      culture,
      adventure,
      nature,
      ...continentVector,
    ];
  }
  
  /// Crée depuis un array
  factory DestinationVector.fromArray(String id, List<double> array) {
    if (array.length != 13) {
      throw ArgumentError('DestinationVector requires 13 dimensions, got ${array.length}');
    }
    return DestinationVector(
      destinationId: id,
      temperature: array[0],
      budget: array[1],
      activity: array[2],
      urban: array[3],
      culture: array[4],
      adventure: array[5],
      nature: array[6],
      continentVector: array.sublist(7, 13),
    );
  }
  
  @override
  String toString() {
    return 'DestinationVector($destinationId: temp=${temperature.toStringAsFixed(2)}, '
           'budget=${budget.toStringAsFixed(2)}, activity=${activity.toStringAsFixed(2)}, '
           'urban=${urban.toStringAsFixed(2)})';
  }
  
  /// Convertit un code région en vecteur continent (one-hot)
  /// 'europe' → [1, 0, 0, 0, 0, 0]
  static List<double> regionToVector(String region) {
    final mapping = {
      'europe': 0,
      'africa': 1,
      'asia': 2,
      'north_america': 3,
      'south_america': 4,
      'oceania': 5,
      'middlee_east': 1,  // Regroupé avec Afrique pour simplifier
    };
    
    final vector = List<double>.filled(6, 0.0);
    final index = mapping[region.toLowerCase()];
    if (index != null) {
      vector[index] = 1.0;
    }
    
    return vector;
  }
  
  /// Sérialise en Map pour stockage
  Map<String, dynamic> toJson() {
    return {
      'destinationId': destinationId,
      'vector': toArray(),
    };
  }
  
  /// Désérialise depuis Map
  factory DestinationVector.fromJson(Map<String, dynamic> json) {
    return DestinationVector.fromArray(
      json['destinationId'] as String,
      (json['vector'] as List).cast<double>(),
    );
  }
}
