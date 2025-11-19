import 'package:flutter/material.dart';

class ContinentSelectionPage extends StatefulWidget {
  const ContinentSelectionPage({super.key});

  @override
  State<ContinentSelectionPage> createState() => _ContinentSelectionPageState();
}

class _ContinentSelectionPageState extends State<ContinentSelectionPage> {
  // Map pour stocker l'état de sélection de chaque continent
  final Map<String, bool> selectedContinents = {
    'Afrique': false,
    'Amérique du Nord': false,
    'Amérique du Sud': false,
    'Asie': false,
    'Europe': false,
    'Océanie': false,
  };

  void _toggleContinent(String continent) {
    setState(() {
      selectedContinents[continent] = !selectedContinents[continent]!;
    });
  }

  void _nextQuestion() {
    // Récupérer les continents sélectionnés
    List<String> selected = selectedContinents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selected.isEmpty) {
      // Afficher un message si aucun continent n'est sélectionné
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un continent'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigation vers la prochaine question
    print('Continents sélectionnés: $selected');
    // TODO: Navigator.push vers la page suivante
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildQuestionTitle(),
              const SizedBox(height: 40),
              Expanded(
                child: _buildWorldMap(),
              ),
              const SizedBox(height: 30),
              _buildNextButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle() {
    return const Text(
      'Quels continents vous intéressent ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildWorldMap() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rangée 1: Amérique du Nord, Europe, Asie
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContinentCard('Amérique du Nord', Icons.public),
                _buildContinentCard('Europe', Icons.location_city),
                _buildContinentCard('Asie', Icons.temple_buddhist),
              ],
            ),
            const SizedBox(height: 16),
            // Rangée 2: Amérique du Sud, Afrique, Océanie
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContinentCard('Amérique du Sud', Icons.forest),
                _buildContinentCard('Afrique', Icons.wb_sunny),
                _buildContinentCard('Océanie', Icons.waves),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinentCard(String continent, IconData icon) {
    final isSelected = selectedContinents[continent] ?? false;

    return GestureDetector(
      onTap: () => _toggleContinent(continent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        height: 120,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.red,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? Colors.green : Colors.red).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                continent,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final hasSelection = selectedContinents.values.any((selected) => selected);

    return Center(
      child: ElevatedButton(
        onPressed: hasSelection ? _nextQuestion : null,
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
        child: const Text(
          'Question suivante',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}