import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart'; // Importez le modèle

class ActivityTypePage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const ActivityTypePage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<ActivityTypePage> createState() => _ActivityTypePageState();
}

class _ActivityTypePageState extends State<ActivityTypePage> {
  double _activityLevel = 50; // Valeur par défaut (50 = équilibre)

  String get _activityDescription {
    if (_activityLevel < 20) return 'Très campagne';
    if (_activityLevel < 40) return 'Plutôt campagne';
    if (_activityLevel < 60) return 'Équilibré';
    if (_activityLevel < 80) return 'Plutôt ville';
    return 'Très ville';
  }

  void _nextQuestion() {
    // ✅ Sauvegarder les données dans l'objet de préférences
    widget.preferences.activityLevel = _activityLevel;
    
    print('Niveau d\'environnement sélectionné: $_activityLevel - $_activityDescription');
    
    // Appeler le callback de navigation
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuestionTitle(),
              const SizedBox(height: 50),
              _buildActivitySlider(),
              const SizedBox(height: 50),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle() {
    return const Text(
      'Quel lieu de vacances recherchez-vous ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActivitySlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Campagne', style: TextStyle(color: Colors.white)),
            Text('Ville', style: TextStyle(color: Colors.white)),
          ],
        ),
        Slider(
          value: _activityLevel,
          min: 0,
          max: 100,
          divisions: 100,
          label: _activityLevel.round().toString(),
          activeColor: Colors.white,
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: (double value) {
            // ✅ Mettre à jour l'état du curseur
            setState(() {
              _activityLevel = value;
            });
          },
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _activityDescription,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextQuestion,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1a3a52),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
      ),
      child: const Text(
        'Suivant',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

}