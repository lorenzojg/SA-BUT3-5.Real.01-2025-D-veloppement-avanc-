import 'package:flutter/material.dart';

class BudgetSelectionPage extends StatefulWidget {
  const BudgetSelectionPage({super.key});

  @override
  State<BudgetSelectionPage> createState() => _BudgetSelectionPageState();
}

class _BudgetSelectionPageState extends State<BudgetSelectionPage> {
  double _budgetLevel = 2.0; // Valeur par défaut (niveau 2 = €€)

  // Définition des niveaux de budget
  final List<BudgetOption> _budgetOptions = [
    BudgetOption(level: 0, symbol: '€', label: 'Petit budget'),
    BudgetOption(level: 1, symbol: '€€', label: 'Budget modéré'),
    BudgetOption(level: 2, symbol: '€€€', label: 'Budget confortable'),
    BudgetOption(level: 3, symbol: '€€€€', label: 'Budget élevé'),
    BudgetOption(level: 4, symbol: '€€€€€', label: 'Budget illimité'),
  ];

  BudgetOption get _currentBudget => _budgetOptions[_budgetLevel.round()];

  void _nextQuestion() {
    // Récupérer le budget sélectionné
    final selectedBudget = _currentBudget;
    print('Budget sélectionné: ${selectedBudget.symbol} - ${selectedBudget.label}');

    // TODO: Navigation vers la prochaine question
    // Navigator.push(context, MaterialPageRoute(builder: (context) => NextPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuestionTitle(),
              const SizedBox(height: 60),
              _buildBudgetDisplay(),
              const SizedBox(height: 40),
              _buildSlider(),
              const SizedBox(height: 30),
              _buildBudgetLabels(),
              const SizedBox(height: 60),
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
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildBudgetDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _currentBudget.symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _currentBudget.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        trackHeight: 6,
        valueIndicatorColor: Colors.white,
        valueIndicatorTextStyle: const TextStyle(
          color: Color(0xFF1a3a52),
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Slider(
        value: _budgetLevel,
        min: 0,
        max: 4,
        divisions: 4,
        onChanged: (value) {
          setState(() {
            _budgetLevel = value;
          });
        },
      ),
    );
  }

  Widget _buildBudgetLabels() {
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
        'Question suivante',
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