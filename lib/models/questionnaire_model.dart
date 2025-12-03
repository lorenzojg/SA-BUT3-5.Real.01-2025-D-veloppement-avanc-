class Question {
  final String title;
  final String? subtitle;
  final List<String> options;

  Question({
    required this.title,
    this.subtitle,
    required this.options,
  });
}

class QuestionnaireData {
  static List<Question> getQuestions() {
    return [
      Question(
        title: 'Quelques petites questions avant de\ncommencer l\'expérience',
        subtitle: 'Quel est votre budget du moment ?',
        options: [
          '< 500€',
          '< 500€ et > 1000€',
          '< 1000€ et > 2000€',
          '> 2000€',
          'Sans précision de budget',
        ],
      ),
      Question(
        title: 'Quelle est ta destination ?',
        options: [
          'Europe',
          'Afrique',
          'Amérique du Sud',
          'Amérique du Nord',
          'Océanie',
          'Antarctique',
          'Sans préférence',
        ],
      ),
      Question(
        title: 'A combien souhaiteriez vous partir ?',
        options: [
          'En solo',
          'En famille',
          'En couple',
        ],
      ),
    ];
  }
}

class UserPreferences {
  String? budget;
  String? continent;
  String? travelers;

  UserPreferences({
    this.budget,
    this.continent,
    this.travelers,
  });

  void setAnswer(int questionIndex, String answer) {
    switch (questionIndex) {
      case 0:
        budget = answer;
        break;
      case 1:
        continent = answer;
        break;
      case 2:
        travelers = answer;
        break;
    }
  }

  String? getAnswer(int questionIndex) {
    switch (questionIndex) {
      case 0:
        return budget;
      case 1:
        return continent;
      case 2:
        return travelers;
      default:
        return null;
    }
  }

  // --- Nouveaux champs pour l'algorithme avancé ---
  // Ces valeurs seraient idéalement remplies par des questions supplémentaires
  // ou déduites. Pour l'instant, on peut imaginer des valeurs par défaut ou
  // étendre le questionnaire plus tard.

  // Préférence Ville vs Nature (0.0 = 100% Nature, 1.0 = 100% Urbain)
  double prefJaugeVille = 0.5;

  // Préférence Chill vs Actif (0.0 = 100% Chill, 1.0 = 100% Actif)
  double prefJaugeSedentarite = 0.5;

  // Préférence Climat (Seuil de température min acceptable, ex: 15°C)
  double prefJaugeClimat = 15.0;

  @override
  String toString() {
    return 'Budget: $budget\nContinent: $continent\nVoyageurs: $travelers';
  }
}
