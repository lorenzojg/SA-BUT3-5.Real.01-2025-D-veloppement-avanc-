import 'package:flutter/material.dart';
<<<<<<< HEAD

class ContinentSelectionPage extends StatefulWidget {
  const ContinentSelectionPage({super.key});
=======
import '../models/questionnaire_model.dart'; // Importez le modèle

class ContinentSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const ContinentSelectionPage({
    super.key,
    required this.onNext,
    required this.preferences,
  });
>>>>>>> b9aab2b (grosse modif)

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
<<<<<<< HEAD
=======
    'Antarctique': false, // Ajouté pour être exhaustif
>>>>>>> b9aab2b (grosse modif)
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

<<<<<<< HEAD
    // Navigation vers la prochaine question
    print('Continents sélectionnés: $selected');
    // TODO: Navigator.push vers la page suivante
=======
    // ✅ Sauvegarder les données dans l'objet de préférences
    widget.preferences.selectedContinents = selected;
    
    // Appeler le callback de navigation
    widget.onNext();
>>>>>>> b9aab2b (grosse modif)
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQuestionTitle(),
            const SizedBox(height: 30),
            _buildContinentGrid(),
            const SizedBox(height: 50),
            _buildNextButton(),
          ],
>>>>>>> b9aab2b (grosse modif)
        ),
      ),
    );
  }

  Widget _buildQuestionTitle() {
    return const Text(
<<<<<<< HEAD
      'Quels continents vous intéressent ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.4,
=======
      'Avez-vous un continent de\npréférence ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
>>>>>>> b9aab2b (grosse modif)
      ),
    );
  }

<<<<<<< HEAD
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
=======
  Widget _buildContinentGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: selectedContinents.keys.map((continent) {
        return _buildContinentCard(
          continent,
          _getContinentIcon(continent),
          selectedContinents[continent]!,
        );
      }).toList(),
    );
  }

  IconData _getContinentIcon(String continent) {
    switch (continent) {
      case 'Europe':
        return Icons.public;
      case 'Afrique':
        return Icons.castle;
      case 'Amérique du Nord':
        return Icons.deck;
      case 'Amérique du Sud':
        return Icons.park;
      case 'Asie':
        return Icons.temple_hindu;
      case 'Océanie':
        return Icons.beach_access;
      case 'Antarctique':
        return Icons.ac_unit;
      default:
        return Icons.travel_explore;
    }
  }

  Widget _buildContinentCard(
      String continent, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleContinent(continent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
>>>>>>> b9aab2b (grosse modif)
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
<<<<<<< HEAD
          'Question suivante',
=======
          'Suivant',
>>>>>>> b9aab2b (grosse modif)
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}