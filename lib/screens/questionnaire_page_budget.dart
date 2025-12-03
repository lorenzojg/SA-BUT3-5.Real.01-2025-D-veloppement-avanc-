import 'package:flutter/material.dart';

import '../models/questionnaire_model.dart'; // Importez le modèle

class BudgetSelectionPage extends StatefulWidget {
  final VoidCallback onFinish;
  final UserPreferences preferences;

  const BudgetSelectionPage({
    super.key,
    required this.onFinish,
    required this.preferences,
  });

  @override
  State<BudgetSelectionPage> createState() => _BudgetSelectionPageState();
}

class _BudgetSelectionPageState extends State<BudgetSelectionPage> {
  double _budgetLevel = 2.0; // Valeur par défaut (niveau 2 = €€€)

  final List<BudgetOption> _budgetOptions = [
    BudgetOption(level: 0, symbol: '€', label: 'Petit budget'),
    BudgetOption(level: 1, symbol: '€€', label: 'Budget modéré'),
    BudgetOption(level: 2, symbol: '€€€', label: 'Budget confortable'),
    BudgetOption(level: 3, symbol: '€€€€', label: 'Budget élevé'),
    BudgetOption(level: 4, symbol: '€€€€€', label: 'Budget illimité'),
  ];

  BudgetOption get _currentBudget => _budgetOptions[_budgetLevel.round()];

  void _nextQuestion() {

    // ✅ Sauvegarder les données dans l'objet de préférences
    widget.preferences.budgetLevel = _budgetLevel;

    final selectedBudget = _currentBudget;
    print('Budget sélectionné: ${selectedBudget.symbol} - ${selectedBudget.label}');
    
    // Appeler le callback de fin de questionnaire
    widget.onFinish();
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
              _buildBudgetSlider(),
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
      'Quel est votre budget ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }


  Widget _buildBudgetSlider() {
    return Column(
      children: [
        _buildBudgetSymbols(),
        Slider(
          value: _budgetLevel,
          min: 0,
          max: 4,
          divisions: 4,
          label: _currentBudget.symbol,
          activeColor: Colors.white,
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: (double value) {
            // ✅ Mettre à jour l'état du curseur
            setState(() {
              _budgetLevel = value;
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
            _currentBudget.label,
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

  Widget _buildBudgetSymbols() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _budgetOptions.map((option) {
        final isSelected = _budgetLevel.round() == option.level;
        return Expanded(
          child: Text(
            option.symbol,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.4),
              fontSize: isSelected ? 18 : 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton() {
    // Le bouton final
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
        'Voir mes recommandations', // ✅ Changement du texte pour le bouton final
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// Classe pour représenter une option de budget
class BudgetOption {
  final int level;
  final String symbol;
  final String label;

  BudgetOption({
    required this.level,
    required this.symbol,
    required this.label,
  });
}