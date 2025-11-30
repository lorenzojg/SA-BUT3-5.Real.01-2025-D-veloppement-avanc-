import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../services/database_service.dart';
import '../models/recommendation_service.dart'; // ✅ Changé de models/ à services/
import 'contact_page.dart';
import 'about_page.dart';
import 'reset_preferences_page.dart';

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
  List<Destination> _allDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    print('🔄 Chargement des destinations depuis SQLite...');

    try {
      _allDestinations = await _dbService.getAllDestinations();
      print('📊 ${_allDestinations.length} destinations en base');
      
      print('\n🎯 Préférences utilisateur :');
      print(widget.userPreferences.toString());

      final recommendedDestinations = RecommendationService.filterAndSortDestinations(
        _allDestinations,
        widget.userPreferences,
      );

      print('\n✅ ${recommendedDestinations.length} destinations correspondent aux critères');
      
      final stats = RecommendationService.getRecommendationStats(
        _allDestinations,
        recommendedDestinations,
        widget.userPreferences,
      );

      setState(() {
        _destinations = recommendedDestinations;
        _stats = stats;
        _isLoading = false;
      });

      print('\n📈 Statistiques : ${stats['matchingDestinations']}/${stats['totalDestinations']} destinations (${stats['filterRate']})');
    } catch (e) {
      print('❌ ERREUR lors du chargement des recommandations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPage(String page) {
    Navigator.pop(context); // Fermer le drawer

    switch (page) {
      case 'contact':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactPage()),
        );
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutPage()),
        );
        break;
      case 'reset':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPreferencesPage(
              userPreferences: widget.userPreferences,
            ),
          ),
        );
        break;
      case 'home':
        // Déjà sur la page d'accueil
        break;
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1a3a52),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade900,
                      Colors.blue.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.travel_explore,
                      size: 60,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Serendia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Votre guide voyage',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(
                icon: Icons.home,
                title: 'Accueil',
                onTap: () => _navigateToPage('home'),
              ),
              const Divider(color: Colors.white24),
              _buildDrawerItem(
                icon: Icons.refresh,
                title: 'Recommencer',
                onTap: () => _navigateToPage('reset'),
              ),
              _buildDrawerItem(
                icon: Icons.info_outline,
                title: 'À propos',
                onTap: () => _navigateToPage('about'),
              ),
              _buildDrawerItem(
                icon: Icons.email_outlined,
                title: 'Contactez-nous',
                onTap: () => _navigateToPage('contact'),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _destinations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    if (_stats != null) _buildStatsHeader(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _destinations.length,
                        itemBuilder: (context, index) {
                          final destination = _destinations[index];
                          final rank = index + 1;
                          return _buildDestinationCard(destination, rank);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.1),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_stats!['matchingDestinations']} destinations trouvées',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.white30, height: 20),
          _buildStatRow('Budget', _stats!['budget']),
          _buildStatRow('Activité', _stats!['activity']),
          _buildStatRow('Continents', _stats!['continent']),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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

  Widget _buildDestinationCard(Destination destination, int rank) {
    final activityMatch = widget.userPreferences.activityLevel != null
        ? 100 - (destination.activityScore - widget.userPreferences.activityLevel!).abs().round()
        : 0;
    
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                  if (widget.userPreferences.activityLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen.shade700.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.lightGreen.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Match Activité: $activityMatch%',
                        style: TextStyle(
                          color: Colors.lightGreen.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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