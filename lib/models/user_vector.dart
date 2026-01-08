

/// Vecteur utilisateur pour recommandations vectorielles
/// Dimension : 13 (7 features + 6 continents)
class UserVector {
  // Features continues (normalisées 0-1)
  final double temperature;   // Température préférée normalisée
  final double budget;         // Budget normalisé (0-4 → 0-1)
  final double activity;       // Niveau d'activité (0-100 → 0-1)
  final double urban;          // Préférence urbain (0-100 → 0-1)
  final double culture;        // Intérêt culture (0-1)
  final double adventure;      // Intérêt aventure (0-1)
  final double nature;         // Intérêt nature (0-1)
  
  // Continents (multi-hot encoding)
  final List<double> continentVector; // [europe, afrique, asie, am_nord, am_sud, océanie]
  
  UserVector({
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
  factory UserVector.fromArray(List<double> array) {
    if (array.length != 13) {
      throw ArgumentError('UserVector requires 13 dimensions, got ${array.length}');
    }
    return UserVector(
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
  
  /// Crée un vecteur copie modifiée
  UserVector copyWith({
    double? temperature,
    double? budget,
    double? activity,
    double? urban,
    double? culture,
    double? adventure,
    double? nature,
    List<double>? continentVector,
  }) {
    return UserVector(
      temperature: temperature ?? this.temperature,
      budget: budget ?? this.budget,
      activity: activity ?? this.activity,
      urban: urban ?? this.urban,
      culture: culture ?? this.culture,
      adventure: adventure ?? this.adventure,
      nature: nature ?? this.nature,
      continentVector: continentVector ?? List.from(this.continentVector),
    );
  }
  
  @override
  String toString() {
    return 'UserVector(temp: ${temperature.toStringAsFixed(2)}, budget: ${budget.toStringAsFixed(2)}, '
           'activity: ${activity.toStringAsFixed(2)}, urban: ${urban.toStringAsFixed(2)}, '
           'culture: ${culture.toStringAsFixed(2)}, adventure: ${adventure.toStringAsFixed(2)}, '
           'nature: ${nature.toStringAsFixed(2)}, continents: ${continentVector.map((v) => v.toStringAsFixed(1)).join(",")})';
  }
  
  /// Normalise la température (0-40°C → 0-1)
  static double normalizeTemperature(double tempCelsius) {
    return (tempCelsius.clamp(0, 40) / 40.0);
  }
  
  /// Normalise le budget (0-4 → 0-1)
  static double normalizeBudget(double budgetLevel) {
    return (budgetLevel.clamp(0, 4) / 4.0);
  }
  
  /// Convertit des noms de continents en vecteur multi-hot
  /// ['Afrique', 'Asie'] → [0, 1, 1, 0, 0, 0]
  static List<double> continentsToVector(List<String> continents) {
    final mapping = {
      'Europe': 0,
      'Afrique': 1,
      'Asie': 2,
      'Amérique du Nord': 3,
      'Amérique du Sud': 4,
      'Océanie': 5,
    };
    
    final vector = List<double>.filled(6, 0.0);
    for (final continent in continents) {
      final index = mapping[continent];
      if (index != null) {
        vector[index] = 1.0;
      }
    }
    
    return vector;
  }
  
  /// Interpole entre deux vecteurs avec un learning rate
  /// Utilisé pour l'évolution du profil utilisateur
  static UserVector interpolate(UserVector a, UserVector b, double alpha) {
    final arrayA = a.toArray();
    final arrayB = b.toArray();
    final result = List<double>.generate(
      arrayA.length,
      (i) => arrayA[i] * (1 - alpha) + arrayB[i] * alpha,
    );
    return UserVector.fromArray(result);
  }
}
