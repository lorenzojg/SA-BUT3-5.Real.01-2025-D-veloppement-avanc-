import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';
import '../services/database_service.dart';
import 'recommendations_page.dart';


class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  int currentQuestionIndex = 0;
  final List<Question> questions = QuestionnaireData.getQuestions();
  final UserPreferences userPreferences = UserPreferences();
  final DatabaseService _dbService = DatabaseService();

  void _selectAnswer(String answer) {
    setState(() {
      userPreferences.setAnswer(currentQuestionIndex, answer);
    });
  }

  void _nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      await _saveUserPreferences();
      _showResults();
    }
  }

  Future<void> _saveUserPreferences() async {
    // Enregistrer les préférences de l'utilisateur
    print('💾 Préférences sauvegardées');
  }

  void _showResults() {
    // ✅ Naviguer vers la page de recommandations
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsPage(
          userPreferences: userPreferences,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];
    final selectedAnswer = userPreferences.getAnswer(currentQuestionIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuestionTitle(currentQuestion),
              const SizedBox(height: 30),
              _buildOptionsContainer(currentQuestion, selectedAnswer),
              const SizedBox(height: 30),
              _buildNextButton(selectedAnswer),
              const SizedBox(height: 20),
              _buildProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle(Question question) {
    return Text(
      question.title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w300,
        height: 1.6,
      ),
    );
  }

  Widget _buildOptionsContainer(Question question, String? selectedAnswer) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (question.subtitle != null) ...[
            Text(
              question.subtitle!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
          ],
          ...question.options.map(
                (option) => _buildOptionButton(option, selectedAnswer),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, String? selectedAnswer) {
    final isSelected = selectedAnswer == option;

    return GestureDetector(
      onTap: () => _selectAnswer(option),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          '• $option',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(String? selectedAnswer) {
    return ElevatedButton(
      onPressed: selectedAnswer != null ? _nextQuestion : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1a3a52),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
        disabledBackgroundColor: Colors.white.withOpacity(0.5),
      ),
      child: Text(
        currentQuestionIndex == questions.length - 1 ? 'Terminer' : 'Suivant',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Text(
      'Question ${currentQuestionIndex + 1}/${questions.length}',
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 14,
      ),
    );
  }
}
