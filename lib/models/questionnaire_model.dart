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
    // Les questions traditionnelles ne sont plus utilisées par le QuestionnairePage Manager
    // mais sont conservées comme référence.
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
  // ✅ Champs pour les réponses du questionnaire par étapes (les seuls utilisés)
  List<String> selectedContinents = []; // Sélection multiple
  double? budgetLevel; // Valeur du curseur (0.0 à 4.0)
  double? activityLevel; // Valeur du curseur (0.0 à 100.0)
  String? travelers; // 'En solo', 'En couple', 'En famille'

  // Anciens champs supprimés pour éviter la confusion dans le RecoService

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
    final budget = budgetLevel != null ? budgetLevel!.round() : 'N/A';
    final activity = activityLevel != null ? activityLevel!.round() : 'N/A';

    return 'UserPreferences: \n'
        '  Continents: ${selectedContinents.join(', ')}\n'
        '  Voyageurs: ${travelers ?? "Non spécifié"}\n'
        '  Ville/Nature: ${(prefJaugeVille * 100).toStringAsFixed(0)}% Ville\n'
        '  Climat: ${prefJaugeClimat.toStringAsFixed(1)}°C\n'
        '  Niveau Budget: $budget\n'
        '  Niveau Activité: $activity';
  }
}