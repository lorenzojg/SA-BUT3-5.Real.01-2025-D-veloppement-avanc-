import 'user_vector_model.dart';

/// Modèle de préférences utilisateur basé sur le questionnaire
/// Utilisé pour le cold start et l'apprentissage continu
class UserPreferencesV2 {
  // === Réponses du questionnaire (6 items) ===
  
  /// Continents sélectionnés (ex: ['Europe', 'Asie'])
  final List<String> selectedContinents;
  
  /// Poids de chaque continent (pour affiner les recommandations au fil du temps)
  /// Si null, utilise des poids égaux
  final Map<String, double>? continentWeights;
  
  /// Température minimale souhaitée (en °C)
  /// Ex: 15°C = climat doux minimum, 25°C = climat chaud
  final double minTemperature;
  
  /// Niveau d'activité: 0 = 100% détente, 100 = 100% sportif
  final double activityLevel;
  
  /// Préférence Nature vs Ville: 0 = 100% nature, 100 = 100% ville
  final double urbanLevel;
  
  /// Nombre de voyageurs: 'En solo', 'En couple', 'En famille'
  final String travelers;
  
  /// Niveau de budget: 0 = petit budget, 4 = budget illimité
  final double budgetLevel;
  
  // === Paramètres optionnels (pour affinage futur) ===
  
  /// Mois de voyage prévu (1-12), null si non spécifié
  final int? travelMonth;
  
  /// Durée souhaitée en jours
  final int? durationDays;

  UserPreferencesV2({
    required this.selectedContinents,
    this.continentWeights,
    required this.minTemperature,
    required this.activityLevel,
    required this.urbanLevel,
    required this.travelers,
    required this.budgetLevel,
    this.travelMonth,
    this.durationDays,
  });

  /// Crée des préférences par défaut (neutres)
  factory UserPreferencesV2.neutral() {
    return UserPreferencesV2(
      selectedContinents: [],
      minTemperature: 15.0,
      activityLevel: 50.0,
      urbanLevel: 50.0,
      travelers: 'En solo',
      budgetLevel: 2.0,
    );
  }

  /// Convertit depuis l'ancien modèle UserPreferences
  factory UserPreferencesV2.fromLegacy(dynamic oldPrefs) {
    return UserPreferencesV2(
      selectedContinents: oldPrefs.selectedContinents ?? [],
      minTemperature: oldPrefs.prefJaugeClimat ?? 15.0,
      activityLevel: oldPrefs.activityLevel ?? 50.0,
      urbanLevel: (oldPrefs.prefJaugeVille ?? 0.5) * 100,
      travelers: oldPrefs.travelers ?? 'En solo',
      budgetLevel: oldPrefs.budgetLevel ?? 2.0,
    );
  }

  /// Crée une copie avec des modifications
  UserPreferencesV2 copyWith({
    List<String>? selectedContinents,
    Map<String, double>? continentWeights,
    double? minTemperature,
    double? activityLevel,
    double? urbanLevel,
    String? travelers,
    double? budgetLevel,
    int? travelMonth,
    int? durationDays,
  }) {
    return UserPreferencesV2(
      selectedContinents: selectedContinents ?? this.selectedContinents,
      continentWeights: continentWeights ?? this.continentWeights,
      minTemperature: minTemperature ?? this.minTemperature,
      activityLevel: activityLevel ?? this.activityLevel,
      urbanLevel: urbanLevel ?? this.urbanLevel,
      travelers: travelers ?? this.travelers,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      travelMonth: travelMonth ?? this.travelMonth,
      durationDays: durationDays ?? this.durationDays,
    );
  }

  /// Conversion en JSON (pour sauvegarde)
  Map<String, dynamic> toJson() {
    return {
      'selectedContinents': selectedContinents,
      'continentWeights': continentWeights,
      'minTemperature': minTemperature,
      'activityLevel': activityLevel,
      'urbanLevel': urbanLevel,
      'travelers': travelers,
      'budgetLevel': budgetLevel,
      'travelMonth': travelMonth,
      'durationDays': durationDays,
    };
  }

  /// Création depuis JSON
  factory UserPreferencesV2.fromJson(Map<String, dynamic> json) {
    return UserPreferencesV2(
      selectedContinents: List<String>.from(json['selectedContinents'] ?? []),
      continentWeights: json['continentWeights'] != null 
          ? Map<String, double>.from(json['continentWeights'])
          : null,
      minTemperature: (json['minTemperature'] as num?)?.toDouble() ?? 15.0,
      activityLevel: (json['activityLevel'] as num?)?.toDouble() ?? 50.0,
      urbanLevel: (json['urbanLevel'] as num?)?.toDouble() ?? 50.0,
      travelers: json['travelers'] as String? ?? 'En solo',
      budgetLevel: (json['budgetLevel'] as num?)?.toDouble() ?? 2.0,
      travelMonth: json['travelMonth'] as int?,
      durationDays: json['durationDays'] as int?,
    );
  }

  /// Convertit en UserVector pour calculs vectoriels
  UserVector toVector() {
    // Inférer les intérêts culture/adventure/nature depuis les préférences
    final double culture = urbanLevel / 100.0; // Ville = plus de culture
    final double adventure = activityLevel / 100.0; // Activité = aventure
    final double nature = 1.0 - (urbanLevel / 100.0); // Nature inverse de ville
    
    // Utiliser les poids sauvegardés ou créer des poids égaux
    List<double> continentVec;
    if (continentWeights != null && continentWeights!.isNotEmpty) {
      // Convertir le Map en vecteur de 6 dimensions
      continentVec = UserVector.weightsMapToVector(continentWeights!);
    } else {
      // Poids égaux par défaut
      continentVec = UserVector.continentsToWeightedVector(selectedContinents);
    }
    
    return UserVector(
      temperature: UserVector.normalizeTemperature(minTemperature),
      budget: UserVector.normalizeBudget(budgetLevel),
      activity: activityLevel / 100.0,
      urban: urbanLevel / 100.0,
      culture: culture,
      adventure: adventure,
      nature: nature,
      continentVector: continentVec,
    );
  }

  @override
  String toString() {
    return 'UserPreferencesV2:\n'
        '  🌍 Continents: ${selectedContinents.join(", ")}\n'
        '  🌡️ Temp min: ${minTemperature.toStringAsFixed(1)}°C\n'
        '  🏃 Activité: ${activityLevel.toStringAsFixed(0)}/100\n'
        '  🏙️ Urbain: ${urbanLevel.toStringAsFixed(0)}/100\n'
        '  👥 Voyageurs: $travelers\n'
        '  💰 Budget: ${budgetLevel.toStringAsFixed(1)}/4';
  }
}

