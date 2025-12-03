import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';

class ClimatPage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const ClimatPage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<ClimatPage> createState() => _ClimatPageState();
}

class _ClimatPageState extends State<ClimatPage> {
  double _value = 20.0; // Température par défaut

  void _nextQuestion() {
    widget.preferences.prefJaugeClimat = _value;
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
                'Quelle est votre température idéale ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              Text(
                '${_value.round()}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: _value,
                min: -10.0,
                max: 40.0,
                divisions: 50,
                label: '${_value.round()}°C',
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.3),
                onChanged: (val) {
                  setState(() {
                    _value = val;
                  });
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Froid ❄️  ----------------  Chaud ☀️',
                style: TextStyle(color: Colors.white70),
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
