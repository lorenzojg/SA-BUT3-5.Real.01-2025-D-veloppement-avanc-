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
        title: 'Avez-vous un continent de\npréférence ?',
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

  // Anciens champs supprimés pour éviter la confusion dans le RecoService

  @override
  String toString() {
    final budget = budgetLevel != null ? budgetLevel!.round() : 'N/A';
    final activity = activityLevel != null ? activityLevel!.round() : 'N/A';

    return 'UserPreferences: \n'
        '  Continents: ${selectedContinents.join(', ')}\n'
        '  Niveau Budget: $budget\n'
        '  Niveau Activité: $activity';
  }
}