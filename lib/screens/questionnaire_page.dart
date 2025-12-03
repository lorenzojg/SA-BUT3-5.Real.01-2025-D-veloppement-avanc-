import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';
import '../services/database_service.dart';
import 'recommendations_page.dart';
import 'WorldMap.dart'; // <--- 1. IMPORTER LA CARTE

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

  // Pour stocker temporairement la sélection de la carte (qui est une liste)
  // avant de la convertir en String pour ton modèle actuel.
  List<WorldRegion> _tempSelectedRegions = [];

  void _selectAnswer(String answer) {
    setState(() {
      userPreferences.setAnswer(currentQuestionIndex, answer);
    });
  }

  void _nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _tempSelectedRegions = []; // Reset pour la prochaine question
      });
    } else {
      await _saveUserPreferences();
      _showResults();
    }
  }

  Future<void> _saveUserPreferences() async {
    print('💾 Préférences sauvegardées');
    // _dbService.save(...)
  }

  void _showResults() {
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
          padding: const EdgeInsets.all(20.0), // J'ai réduit un peu le padding pour laisser place à la carte
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuestionTitle(currentQuestion),
              const SizedBox(height: 20),
              
              // Le contenu principal change si c'est une carte ou du texte
              Expanded(
                child: Center(
                  child: _buildOptionsContainer(currentQuestion, selectedAnswer),
                ),
              ),
              
              const SizedBox(height: 20),
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
        fontSize: 22, // Un peu plus grand pour le titre
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
  }

  Widget _buildOptionsContainer(Question question, String? selectedAnswer) {
    // <--- 2. LOGIQUE DE DÉTECTION
    // Ici, on doit savoir si c'est la question "Carte".
    // Option A : Tu ajoutes un champ 'type' dans ton modèle Question.
    // Option B (Utilisée ici) : On vérifie si le titre contient "monde" ou "destination".
    // Adapter cette condition selon le vrai titre de ta question dans QuestionnaireData.
    bool isMapQuestion = question.title.toLowerCase().contains("destination") || 
                         question.title.toLowerCase().contains("monde");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: isMapQuestion 
        ? _buildMapContent() // Affiche la carte
        : _buildStandardOptions(question, selectedAnswer), // Affiche les boutons classiques
    );
  }

  // <--- 3. LE WIDGET CARTE INTÉGRÉ
  Widget _buildMapContent() {
    return Column(
      mainAxisSize: MainAxisSize.min, // S'adapte au contenu
      children: [
        const Text(
          "Touchez les zones sur la carte",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 15),
        // On donne une taille fixe à la carte pour qu'elle s'affiche bien dans la colonne
        SizedBox(
          height: 300, // Ajuste la hauteur selon tes besoins
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            // On enveloppe la carte dans un container blanc ou transparent selon tes gouts
            // Ici je mets un fond transparent pour qu'on voit juste les pays
            child: WorldMapSelector(
              onRegionsChanged: (regions) {
                setState(() {
                  _tempSelectedRegions = regions;
                  
                  // CONVERSION : Ta méthode _selectAnswer attend un String.
                  // On transforme la liste de régions en String (ex: "Europe,Asie").
                  // Si la liste est vide, on passe null ou chaine vide.
                  if (regions.isEmpty) {
                    _selectAnswer(""); // ou gérer le null
                  } else {
                    String result = regions.map((e) => e.name).join(',');
                    _selectAnswer(result);
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Petit feedback textuel
        if (_tempSelectedRegions.isNotEmpty)
          Text(
            "Sélection : ${_tempSelectedRegions.map((e) => e.name).join(', ')}", // Affiche proprement les noms
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  // J'ai extrait l'ancien contenu de _buildOptionsContainer ici pour plus de clarté
  Widget _buildStandardOptions(Question question, String? selectedAnswer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (question.subtitle != null) ...[
          Text(
            question.subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
        ],
        // Génère la liste des boutons
        ...question.options.map(
          (option) => _buildOptionButton(option, selectedAnswer),
        ),
      ],
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
    // Le bouton est activé si selectedAnswer n'est pas null et n'est pas vide
    bool isEnabled = selectedAnswer != null && selectedAnswer.isNotEmpty;

    return ElevatedButton(
      onPressed: isEnabled ? _nextQuestion : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1a3a52),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
        disabledBackgroundColor: Colors.white.withOpacity(0.3), // Plus joli désactivé
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