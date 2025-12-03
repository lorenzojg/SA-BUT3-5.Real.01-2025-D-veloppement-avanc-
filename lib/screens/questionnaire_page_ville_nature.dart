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
  double _value = 0.5; // 0.0 = Nature, 1.0 = Ville

  void _nextQuestion() {
    widget.preferences.prefJaugeVille = _value;
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
              const Text(
                'Préférez-vous la Ville ou la Nature ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Nature 🌲', style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('Ville 🏙️', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              Slider(
                value: _value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.3),
                onChanged: (val) {
                  setState(() {
                    _value = val;
                  });
                },
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1a3a52),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Suivant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
