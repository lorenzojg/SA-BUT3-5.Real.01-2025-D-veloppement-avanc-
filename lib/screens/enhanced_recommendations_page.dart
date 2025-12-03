import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../models/user_interaction_model.dart';
import '../services/database_service.dart';
import '../services/enhanced_recommendation_service.dart';
import '../services/favorites_service.dart';
import '../services/activity_analyzer_service.dart';
import 'destination_detail_page.dart';

class EnhancedRecommendationsPage extends StatefulWidget {
  final UserPreferences userPreferences;

  const EnhancedRecommendationsPage({super.key, required this.userPreferences});

  @override
  State<EnhancedRecommendationsPage> createState() =>
      _EnhancedRecommendationsPageState();
}

class _EnhancedRecommendationsPageState
    extends State<EnhancedRecommendationsPage> {
  late EnhancedRecommendationService _recommendationService;
  late DatabaseService _dbService;
  late FavoritesService _favoritesService;
  late ActivityAnalyzerService _activityAnalyzer;

  List<Destination> _allDestinations = [];
  List<Destination> _recommendations = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _recommendationService = EnhancedRecommendationService();
    _dbService = DatabaseService();
    _favoritesService = FavoritesService();
    _activityAnalyzer = ActivityAnalyzerService();

    _recommendationService.initialize(preferences: widget.userPreferences);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _allDestinations = await _dbService.getAllDestinations();
      _favoriteIds = await _favoritesService.getFavoriteIds();

      // Générer les recommandations enrichies
      _recommendations = _recommendationService.getEnhancedRecommendations(
        _allDestinations,
        limit: 15,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _recordInteraction(String destinationId, InteractionType type) {
    _recommendationService.recordInteraction(destinationId, type);
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleFavorite(Destination destination) async {
    await _favoritesService.toggleFavorite(destination.id);
    _favoriteIds = await _favoritesService.getFavoriteIds();
    _recordInteraction(destination.id, InteractionType.addToFavorites);
    if (mounted) {
      setState(() {});
    }
  }

  void _viewDetails(Destination destination) {
    _recordInteraction(destination.id, InteractionType.viewDetails);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationDetailPage(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recommandations')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recommendations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recommandations')),
        body: const Center(child: Text('Aucune recommandation disponible')),
      );
    }

    final destination = _recommendations[_currentIndex];
    final isFavorite = _favoriteIds.contains(destination.id);
    final activities = _activityAnalyzer.getActivitiesForDestination(
      destination.name,
    );

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recommandations Enrichies'),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_recommendations.length}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // En-tête avec image/couleur
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination.country,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Détails
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Note et prix estimé
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoCard('⭐ Note', '${destination.rating}/5'),
                        _buildInfoCard(
                          '💰 Prix/jour',
                          '€${destination.averageCost.toStringAsFixed(0)}',
                        ),
                        _buildInfoCard(
                          '🎯 Activités',
                          '${destination.activityScore}/100',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Résumé d'activités
                    const Text(
                      'Activités à proximité',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (activities.isNotEmpty)
                      Column(
                        children:
                            activities.take(5).map((activity) {
                              final score = activity.calculateActivityScore();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activity.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            activity
                                                .getPrimaryCategories()
                                                .join(', '),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        '${score.toStringAsFixed(0)}/100',
                                      ),
                                      backgroundColor: Colors.blue.shade100,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      )
                    else
                      const Text(
                        'Pas d\'activités détaillées disponibles',
                        style: TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 20),
                    // Climatologie
                    const Text(
                      'Climatologie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination.climate,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton Précédent
                ElevatedButton.icon(
                  onPressed:
                      _currentIndex > 0
                          ? () {
                            setState(() {
                              _currentIndex--;
                            });
                          }
                          : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Précédent'),
                ),
                // Bouton Favoris
                ElevatedButton.icon(
                  onPressed: () => _toggleFavorite(destination),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(isFavorite ? 'Aimé' : 'Aimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFavorite ? Colors.red : Colors.grey,
                  ),
                ),
                // Bouton Détails
                ElevatedButton.icon(
                  onPressed: () => _viewDetails(destination),
                  icon: const Icon(Icons.info),
                  label: const Text('Détails'),
                ),
                // Bouton Suivant
                ElevatedButton.icon(
                  onPressed:
                      _currentIndex < _recommendations.length - 1
                          ? () {
                            setState(() {
                              _currentIndex++;
                            });
                          }
                          : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Suivant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
