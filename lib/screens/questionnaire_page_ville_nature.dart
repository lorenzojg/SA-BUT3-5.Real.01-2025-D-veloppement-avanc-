import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';

class VilleNaturePage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const VilleNaturePage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<VilleNaturePage> createState() => _VilleNaturePageState();
}

class _VilleNaturePageState extends State<VilleNaturePage> {
  // On utilise une échelle de 0 à 100 pour le slider (design Leona)
  double _sliderValue = 50.0;

  // On convertit en 0.0 - 1.0 pour le modèle (0.0 = Nature, 1.0 = Ville)
  double get _normalizedValue => _sliderValue / 100.0;

  String get _description {
    if (_sliderValue < 20) return 'Très Nature 🌲';
    if (_sliderValue < 40) return 'Plutôt Nature 🌳';
    if (_sliderValue < 60) return 'Équilibré ⚖️';
    if (_sliderValue < 80) return 'Plutôt Ville 🏙️';
    return 'Très Ville 🌃';
  }

  void _nextQuestion() {
    // Sauvegarde dans le modèle existant (0.0 à 1.0)
    widget.preferences.prefJaugeVille = _normalizedValue;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildQuestionTitle(),
                const SizedBox(height: 50),
                _buildSlider(),
                const SizedBox(height: 50),
                _buildNextButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle() {
    return const Text(
      'Quel environnement préférez-vous ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Nature 🌲', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('Ville 🏙️', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Slider(
          value: _sliderValue,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: Colors.white,
          inactiveColor: Colors.white54,
          onChanged: (value) {
            setState(() => _sliderValue = value);
          },
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30, width: 1),
          ),
          child: Text(
            _description,
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
      ),
      child: const Text(
        'Suivant',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
