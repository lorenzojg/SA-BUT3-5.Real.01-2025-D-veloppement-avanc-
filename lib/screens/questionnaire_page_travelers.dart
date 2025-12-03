import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';

class TravelersSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const TravelersSelectionPage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<TravelersSelectionPage> createState() => _TravelersSelectionPageState();
}

class _TravelersSelectionPageState extends State<TravelersSelectionPage> {
  String? _selectedOption;

  final List<String> _options = [
    'En solo',
    'En couple',
    'En famille',
  ];

  void _handleSelection(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _nextQuestion() {
    if (_selectedOption != null) {
      widget.preferences.travelers = _selectedOption;
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une option')),
      );
    }
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
                'À combien souhaitez-vous partir ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              ..._options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildOptionButton(option),
              )),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _selectedOption != null ? _nextQuestion : null,
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

  Widget _buildOptionButton(String option) {
    final isSelected = _selectedOption == option;
    return InkWell(
      onTap: () => _handleSelection(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Text(
          option,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1a3a52) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
