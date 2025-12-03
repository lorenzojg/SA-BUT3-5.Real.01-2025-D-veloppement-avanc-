class UserPreferences {
  // ===== PRÉFÉRENCES EXISTANTES =====
  List<String>? selectedContinents;
  double? activityLevel;
  double? budgetLevel;
  
  // ===== NOUVELLES PRÉFÉRENCES =====
  double? temperaturePreference;  // 0-100 (0=froid, 100=tropical)
  String? travelGroup;            // 'solo', 'couple', 'friends', 'family'
  int? travelGroupSize;           // Nombre de personnes (1, 2, 4)

  UserPreferences({
    this.selectedContinents,
    this.activityLevel,
    this.budgetLevel,
    this.temperaturePreference,
    this.travelGroup,
    this.travelGroupSize,
  });

  @override
  String toString() {
    return '''
    UserPreferences {
      continents: $selectedContinents,
      activityLevel: $activityLevel,
      budgetLevel: $budgetLevel,
      temperaturePreference: $temperaturePreference,
      travelGroup: $travelGroup,
      travelGroupSize: $travelGroupSize,
    }
    ''';
  }

  // Méthode pour obtenir le label du groupe de voyage
  String getTravelGroupLabel() {
    switch (travelGroup) {
      case 'solo':
        return 'En solo';
      case 'couple':
        return 'En couple';
      case 'friends':
        return 'Entre ami(e)s';
      case 'family':
        return 'En famille';
      default:
        return 'Non défini';
    }
  }

  // Méthode pour obtenir la description de la température
  String getTemperatureLabel() {
    if (temperaturePreference == null) return 'Non défini';
    
    if (temperaturePreference! < 20) return 'Très froid';
    if (temperaturePreference! < 40) return 'Froid / Frais';
    if (temperaturePreference! < 60) return 'Tempéré';
    if (temperaturePreference! < 80) return 'Chaud';
    return 'Très chaud / Tropical';
  }
}