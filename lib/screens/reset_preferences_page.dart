import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';

class ResetPreferencesPage extends StatelessWidget {
  final UserPreferences userPreferences;

  const ResetPreferencesPage({
    super.key,
    required this.userPreferences,
  });

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a3a52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text(
                'Confirmation',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer vos préférences et recommencer le questionnaire ?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Fermer le dialogue
                Navigator.popUntil(context, (route) => route.isFirst); // Retour au début
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Préférences réinitialisées. Recommencez le questionnaire !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a3a52),
        title: const Text(
          'Mes Préférences',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade900,
                    Colors.blue.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Vos préférences actuelles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Consultez les critères utilisés pour vos recommandations',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildPreferenceCard(
              icon: Icons.attach_money,
              title: 'Budget quotidien',
              value: _getBudgetText(userPreferences.budgetLevel),
              color: Colors.green,
            ),
            const SizedBox(height: 15),
            _buildPreferenceCard(
              icon: Icons.directions_run,
              title: 'Niveau d\'activité',
              value: _getActivityText(userPreferences.activityLevel),
              color: Colors.orange,
            ),
            const SizedBox(height: 15),
            _buildPreferenceCard(
              icon: Icons.public,
              title: 'Continents sélectionnés',
              value: userPreferences.selectedContinents?.join(', ') ?? 'Aucun',
              color: Colors.blue,
            ),
            const SizedBox(height: 15),
            _buildPreferenceCard(
              icon: Icons.thermostat,
              title: 'Préférence de température',
              value: userPreferences.getTemperatureLabel(),
              color: Colors.red,
            ),
            const SizedBox(height: 15),
            _buildPreferenceCard(
              icon: Icons.group,
              title: 'Type de voyage',
              value: userPreferences.getTravelGroupLabel() + 
                     (userPreferences.travelGroupSize != null 
                         ? ' (${userPreferences.travelGroupSize} ${userPreferences.travelGroupSize! > 1 ? "personnes" : "personne"})' 
                         : ''),
              color: Colors.purple,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.refresh,
                    size: 50,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Recommencer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vous souhaitez modifier vos préférences et obtenir de nouvelles recommandations ?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showResetConfirmation(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Supprimer et recommencer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBudgetText(double? budgetLevel) {
    if (budgetLevel == null) return 'Non défini';
    
    if (budgetLevel == 0) return '€ - Petit budget';
    if (budgetLevel == 1) return '€€ - Budget modéré';
    if (budgetLevel == 2) return '€€€ - Budget confortable';
    if (budgetLevel == 3) return '€€€€ - Budget élevé';
    if (budgetLevel == 4) return '€€€€€ - Budget illimité';
    
    return 'Non défini';
  }

  String _getActivityText(double? level) {
    if (level == null) return 'Non défini';
    
    final roundedLevel = level.round();
    
    if (level < 20) return 'Très détente (${roundedLevel}/100)';
    if (level < 40) return 'Plutôt détente (${roundedLevel}/100)';
    if (level < 60) return 'Équilibré (${roundedLevel}/100)';
    if (level < 80) return 'Plutôt sportif (${roundedLevel}/100)';
    return 'Très sportif (${roundedLevel}/100)';
  }
}