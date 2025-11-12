import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../services/database_service.dart';
import '../services/recommendation_service.dart'; // ✅ Import

class RecommendationsPage extends StatefulWidget {
  final UserPreferences userPreferences;

  const RecommendationsPage({
    super.key,
    required this.userPreferences,
  });

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final DatabaseService _dbService = DatabaseService();
  List<Destination> _destinations = [];
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadDestinationsFromDatabase();
  }

  Future<void> _loadDestinationsFromDatabase() async {
    print('🔄 Chargement des destinations depuis SQLite...');

    try {
      // Charger toutes les destinations
      final allDestinations = await _dbService.getAllDestinations();
      print('📊 ${allDestinations.length} destinations en base');

      // ✅ Afficher les préférences de l'utilisateur
      print('\n🎯 Préférences utilisateur :');
      print('  Budget: ${widget.userPreferences.budget}');
      print('  Continent: ${widget.userPreferences.continent}');
      print('  Voyageurs: ${widget.userPreferences.travelers}');

      // ✅ Filtrer selon les préférences
      final filteredDestinations = RecommendationService.filterDestinations(
        allDestinations,
        widget.userPreferences,
      );

      print('\n✅ ${filteredDestinations.length} destinations correspondent aux critères');

      // ✅ Trier par pertinence
      final sortedDestinations = RecommendationService.sortByRelevance(
        filteredDestinations,
        widget.userPreferences,
      );

      // ✅ Afficher les 5 premières destinations recommandées
      if (sortedDestinations.isNotEmpty) {
        print('\n🌟 Top 5 recommandations :');
        for (var i = 0; i < (sortedDestinations.length < 5 ? sortedDestinations.length : 5); i++) {
          final dest = sortedDestinations[i];
          print('  ${i + 1}. ${dest.name} (${dest.country}) - ${dest.continent} - ${dest.averageCost.toInt()}\$');
        }
      }

      // ✅ Obtenir les statistiques
      final stats = RecommendationService.getRecommendationStats(
        allDestinations,
        sortedDestinations,
        widget.userPreferences,
      );

      setState(() {
        _destinations = sortedDestinations;
        _stats = stats;
        _isLoading = false;
      });

      print('\n📈 Statistiques : ${stats['matchingDestinations']}/${stats['totalDestinations']} destinations (${stats['filterRate']})');
    } catch (e) {
      print('❌ ERREUR: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a3a52),
        title: const Text(
          'Destinations recommandées',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : _destinations.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          // ✅ Afficher les stats en haut
          if (_stats != null) _buildStatsHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final destination = _destinations[index];
                return _buildDestinationCard(destination);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${_stats!['matchingDestinations']} destinations trouvées',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Budget: ${_stats!['budget']} • ${_stats!['continent']} • ${_stats!['travelers']}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.travel_explore,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune destination trouvée',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1a3a52),
            ),
            child: const Text('Modifier les préférences'),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(Destination destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${destination.country} • ${destination.continent}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${destination.averageCost.toInt()}\$/jour',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber.shade300,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    destination.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (destination.unescoSite) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.amber.shade300,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'UNESCO',
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                destination.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: destination.activities.map((activity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      activity,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
