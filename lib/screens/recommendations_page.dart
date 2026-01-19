import 'dart:math';
import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/user_preferences_model.dart';
import '../services/recommendation_service.dart';
import '../services/destination_service.dart';
import '../services/user_learning_service.dart';
import '../services/favorites_service.dart';
import '../services/recommendations_cache_service.dart';
import '../services/performance_profiler.dart';
import 'contact_page.dart';
import 'about_page.dart';
import 'reset_preferences_page.dart';
import 'favorites_page.dart';
import 'destination_detail_page.dart';
import 'performance_dashboard_page.dart';
import '../services/recent_bias_service.dart';

class RecommendationsPage extends StatefulWidget {
  final UserPreferencesV2 userPreferences;
  final bool isAppStartup; // Indique si c'est le démarrage de l'app

  const RecommendationsPage({
    super.key,
    required this.userPreferences,
    this.isAppStartup = false, // Par défaut, on ne considère pas comme démarrage
  });

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final FavoritesService _favoritesService = FavoritesService();
  final RecommendationServiceV2 _recoService = RecommendationServiceV2();
  final UserLearningService _learningService = UserLearningService();
  final RecommendationsCacheService _cacheService = RecommendationsCacheService();
  final PerformanceProfiler _profiler = PerformanceProfiler();
  final RecentBiasService _biasService = RecentBiasService();


  List<Destination> _destinations = [];
  List<Destination> _gameDestinations = []; // Destinations pour le mini-jeu (tous continents)
  List<RecommendationResult> _results = [];
  late UserPreferencesV2 _userPreferences;

  bool _isLoading = true;

  // Favorites
  Set<String> _favoriteIds = {};

  // Tracking des destinations déjà montrées pour éviter doublons
  final Set<String> _shownDestinationIds = {};
  
  // Tracking des destinations en mode sérendipité
  final Set<String> _serendipityIds = {};

  // --- Mini-jeu state ---
  bool _gameStarted = false;
  int _currentRound = 0; // 1..5
  Destination? _currentChoice;
  final Set<String> _gameSeenIds = {}; // éviter répétitions pendant le jeu
  
  // Learning data for mini-game
  final List<Destination> _likedDestinations = [];
  final List<Destination> _dislikedDestinations = [];

  // Carousel controller
  final ScrollController _carouselController = ScrollController();

  @override
  void initState() {
    super.initState();
    _userPreferences = widget.userPreferences;
    _loadRecommendationsFromCacheOrCompute(useCache: widget.isAppStartup);
    _loadFavorites();
    // Charger destinations pour mini-jeu en arrière-plan (sans await)
    _loadGameDestinations();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    await _favoritesService.initialize();
    setState(() {
      _favoriteIds = _favoritesService.getFavoriteIds();
    });
  }

  /// Charge les recommandations depuis le cache ou les calcule si nécessaire
  /// [useCache] Si true, tente de charger depuis le cache (uniquement au démarrage de l'app)
  Future<void> _loadRecommendationsFromCacheOrCompute({bool useCache = false}) async {
    print('🔄 === CHARGEMENT DES RECOMMANDATIONS ===');
    print('   Use cache: $useCache');
    
    // Tenter de charger depuis le cache UNIQUEMENT si c'est le démarrage de l'app
    if (useCache) {
      final cachedData = await _cacheService.loadRecommendations();
      
      if (cachedData != null) {
        // Cache trouvé et valide
        final destinations = cachedData['destinations'] as List<Destination>;
        final serendipityIds = cachedData['serendipityIds'] as Set<String>;
        
        // Réinitialiser le tracking
        _shownDestinationIds.clear();
        
        setState(() {
          _destinations = destinations;
          _shownDestinationIds.addAll(_destinations.map((d) => d.id));
          _serendipityIds.clear();
          _serendipityIds.addAll(serendipityIds);
          _isLoading = false;
        });
        
        // Recréer les RecommendationResult pour compatibilité
        _results = destinations.map((dest) => RecommendationResult(
          destination: dest,
          totalScore: 0.0, // Score non important ici
          scoreBreakdown: {},
          topActivities: [],
          isSerendipity: serendipityIds.contains(dest.id),
        )).toList();
        
        print('✅ Recommandations chargées depuis le cache');
        return;
      }
      
      print('🔄 Pas de cache valide');
    } else {
      print('🔄 Cache désactivé (pas au démarrage)');
    }
    
    // Calculer les recommandations
    await _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    print('🔄 === CHARGEMENT DES RECOMMANDATIONS ===');
    
    // Réinitialiser le tracking pour cette nouvelle salve
    _shownDestinationIds.clear();
    
    setState(() => _isLoading = true);
    try {
      // Utilisation du système vectoriel avec 10% de sérendipité
      final results = await _recoService.getRecommendationsVectorBased(
        prefs: _userPreferences,
        limit: 20,
        serendipityRatio: 0.10, // 10% de destinations surprenantes
        includeRecentBias: true, // Effet de mode court terme
        excludeIds: _shownDestinationIds, // Exclure les destinations déjà montrées
        profiler: _profiler, // ✅ Passer le profiler pour mesures internes
      );

      print('📋 ${results.length} résultats obtenus');
      
      // Équilibrer les résultats par continent pour le carrousel
      final balancedResults = _recoService.balanceByContinent(
        recommendations: results,
        prefs: _userPreferences,
        targetCount: 20,
      );
      
      setState(() {
        _results = balancedResults;
        _destinations = balancedResults.map((r) => r.destination).toList();
        // Ajouter les nouvelles destinations au tracking
        _shownDestinationIds.addAll(_destinations.map((d) => d.id));
        // Tracker les destinations sérendipité
        _serendipityIds.clear();
        _serendipityIds.addAll(
          balancedResults.where((r) => r.isSerendipity).map((r) => r.destination.id)
        );
        _isLoading = false;
      });
      
      // Sauvegarder dans le cache pour la prochaine ouverture
      _cacheService.saveRecommendations(
        destinations: _destinations,
        serendipityIds: _serendipityIds,
      );
    } catch (e) {
      print('❌ Erreur chargement destinations: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Charge des destinations diversifiées (tous continents) pour le mini-jeu
  /// 50% de sérendipité avec inversion UNIQUEMENT du continent
  Future<void> _loadGameDestinations() async {
    try {
      // Combiner les IDs déjà montrés avec les favoris pour le mini-jeu
      final excludeIdsForGame = Set<String>.from(_shownDestinationIds)
        ..addAll(_favoriteIds);
      
      // Utiliser le système vectoriel avec 50% de sérendipité (continent uniquement)
      final results = await _recoService.getRecommendationsVectorBased(
        prefs: _userPreferences,
        limit: 5, // Seulement 5 destinations pour le mini-jeu
        serendipityRatio: 0.50, // 50% sérendipité
        includeRecentBias: false, // Pas d'effet de mode pour le jeu
        continentOnlySerendipity: true, // UNIQUEMENT inverser le continent
        excludeIds: excludeIdsForGame, // Exclure destinations montrées ET favoris
      );
      
      setState(() {
        _gameDestinations = results.map((r) => r.destination).toList();
      });
      print('🎮 ${_gameDestinations.length} destinations chargées pour le mini-jeu (continent inversé)');
    } catch (e) {
      print('❌ Erreur chargement destinations jeu: $e');
    }
  }

  void _navigateToPage(String page) {
    Navigator.pop(context);

    switch (page) {
      case 'contact':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage()));
        break;
      case 'about':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
        break;
      case 'reset':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResetPreferencesPage(userPreferences: widget.userPreferences)),
        );
        break;
      case 'favorites':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()))
            .then((_) => _loadFavorites());
        break;
      case 'home':
        // nothing
        break;
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a3a52),
        title: const Text('Destinations recommandées', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Performance Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerformanceDashboardPage()),
              );
            },
          ),
        ],
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
                    colors: [Colors.blue.shade900, const Color(0xFF1a3a52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Menu',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                icon: Icons.favorite,
                title: 'Mes Favoris',
                badge: _favoriteIds.isNotEmpty ? _favoriteIds.length : null,
                onTap: () => _navigateToPage('favorites'),
              ),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildContent(),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, int? badge}) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white),
          if (badge != null && badge > 0)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 1) Recommandation principale (grand bloc)
          _buildMainRecommendation(),

          const SizedBox(height: 20),

          // 2) Mini-jeu interactif
          _buildInteractiveGameBox(),

          const SizedBox(height: 20),

          // 3) Carrousel de suggestions
          _buildSimilarDestinationsCarousel(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------------- Main Recommendation ----------------
  Widget _buildMainRecommendation() {
    if (_results.isEmpty) {
      return _buildEmptyStateReplacement();
    }

    final result = _results.first;
    final best = result.destination;
    final isFavorite = _favoriteIds.contains(best.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(
              destination: best,
              rank: 1,
              isSerendipity: result.isSerendipity,
              allDestinations: _destinations,
              currentIndex: 0,
              serendipityIds: _serendipityIds,
            ),
          ),
        ).then((_) => _loadFavorites());
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TOP 1 POUR VOUS',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Image de la destination
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/destinations/${best.id}.jpg',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.landscape,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            
            Text(
              best.city,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              '${best.region}, ${best.country}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTag(Icons.euro, best.budgetLevel),
                const SizedBox(width: 10),
                _buildTag(Icons.wb_sunny, '${DestinationService.getAvgTemp(best, _userPreferences.travelMonth ?? DateTime.now().month)?.toStringAsFixed(1) ?? "--"}°C'),
                const SizedBox(height: 10),
                _buildTag(Icons.landscape, '${best.scoreNature}/5'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              best.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DestinationDetailPage(
                        destination: best,
                        rank: 1,
                        isSerendipity: result.isSerendipity,
                        allDestinations: _destinations,
                        currentIndex: 0,
                        serendipityIds: _serendipityIds,
                      ),
                    ),
                  ).then((_) => _loadFavorites());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Voir les détails', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyStateReplacement() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.travel_explore, size: 60, color: Colors.white54),
          const SizedBox(height: 12),
          const Text('Aucune recommandation disponible', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Essayez de modifier vos préférences', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ---------------- Interactive Game Box ----------------
  Widget _buildInteractiveGameBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 320,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
      child: !_gameStarted ? _buildStartScreen() : _buildGameRound(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Mini-jeu : 5 choix rapides', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Aidez-nous à affiner vos recommandations en notant quelques destinations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('START'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    if (_gameDestinations.isEmpty) {
      print('⚠️ Aucune destination disponible pour le jeu');
      return;
    }

    print('🎮 Démarrage du mini-jeu avec ${_gameDestinations.length} destinations');
    
    setState(() {
      _gameStarted = true;
      _currentRound = 1;
      _gameSeenIds.clear();
      _currentChoice = _getRandomUnseenDestination();
      if (_currentChoice != null) {
        _gameSeenIds.add(_currentChoice!.id);
        print('   🎯 Round 1: ${_currentChoice!.city} (${_currentChoice!.region})');
      }
    });
  }

  Widget _buildGameRound() {
    if (_currentChoice == null) {
      return const Center(child: Text("Plus de destinations à noter", style: TextStyle(color: Colors.white)));
    }

    final dest = _currentChoice!;
    final isFavorite = _favoriteIds.contains(dest.id);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: compteur et "Favoris"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_currentRound/5', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.white54),
                onPressed: () async {
                  // Toggle favorite logic
                  if (isFavorite) {
                    await _favoritesService.removeFavorite(dest.id);
                  } else {
                    await _favoritesService.addFavorite(dest.id);
                  }
                  _loadFavorites();
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Destination affichée avec image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de la destination (toute la place)
                  Image.asset(
                    'assets/images/destinations/${dest.id}.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withOpacity(0.1),
                        child: const Center(
                          child: Icon(Icons.location_city, size: 60, color: Colors.white70),
                        ),
                      );
                    },
                  ),
                  // Gradient pour rendre le texte lisible
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dest.city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            dest.country,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom row: dislike - fav - like
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGameButton(Icons.close, Colors.red.shade400, () => _onUserChoice('dislike')),
              _buildGameButton(Icons.check, Colors.green.shade400, () => _onUserChoice('like')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  // Traitement d'un like/dislike
  Future<void> _onUserChoice(String action) async {
    if (_currentChoice == null) return;

    // 1. Log Interaction
    await _logInteraction(action);

    // Snack
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'like' ? '👍 Intéressant !' : '👎 Pas pour moi'),
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
        )
      );
    }

    // Avancer
    if (_currentRound >= 5) {
      // Masquer immédiatement le jeu avant le recalcul
      setState(() {
        _gameStarted = false;
        _currentRound = 0;
        _currentChoice = null;
        _gameSeenIds.clear();
        _isLoading = true; // Afficher le loader pendant le recalcul
      });
      
      await _finishGameAndRecompute();
    } else {
      setState(() {
        _currentRound++;
        _currentChoice = _getRandomUnseenDestination();
        if (_currentChoice != null) {
          _gameSeenIds.add(_currentChoice!.id);
          print('   🎯 Round $_currentRound: ${_currentChoice!.city} (${_currentChoice!.region})');
        }
      });
    }
  }

  Future<void> _logInteraction(String action) async {
    if (_currentChoice == null) return;

    // 📝 Enregistrer l'interaction pour l'effet de mode court terme
    _recoService.recordInteraction(_currentChoice!, action);

    // Track liked/disliked destinations for learning
    if (action == 'like') {
      _likedDestinations.add(_currentChoice!);
    } else if (action == 'dislike') {
      _dislikedDestinations.add(_currentChoice!);
    }
  }

  Destination? _getRandomUnseenDestination() {
    if (_gameDestinations.isEmpty) return null;
    final candidates = _gameDestinations
      .where((d) => !_gameSeenIds.contains(d.id))
      .toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle(Random());
    return candidates.first;
  }

  Future<void> _finishGameAndRecompute() async {
    try {
      // Update user preferences from mini-game interactions (sans mesure)
      if (_likedDestinations.isNotEmpty || _dislikedDestinations.isNotEmpty) {
        final updatedPrefs = _learningService.updatePreferencesFromInteractions(
          currentPrefs: _userPreferences,
          likedDestinations: _likedDestinations,
          dislikedDestinations: _dislikedDestinations,
        );
        
        setState(() {
          _userPreferences = updatedPrefs;
        });
      }
      
      // Clear interaction lists (sans mesure)
      _likedDestinations.clear();
      _dislikedDestinations.clear();
      
      // Clear cache (sans mesure)
      await _cacheService.clearCache();
      
      // Reload main recommendations (avec mesure - c'est l'important)
      await _loadRecommendations();
      
      // Reload game destinations (sans mesure)
      await _loadGameDestinations();

      // Show success message (sans mesure)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci ! Vos recommandations ont été affinées.'),
            backgroundColor: Colors.green,
          )
        );
      }
      
    } catch (e) {
      print('❌ Error during recommendation recompute: $e');
      rethrow;
    }
  }

  // ---------------- Carousel ----------------
  Widget _buildSimilarDestinationsCarousel() {
    // Exclure la première (main) pour le carrousel
    final list = _destinations.length > 1 ? _destinations.sublist(1) : [];

    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vous pourriez aussi aimer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            height: 220,
            child: ListView.builder(
              controller: _carouselController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                // Trouver le RecommendationResult correspondant
                final result = _results.firstWhere(
                  (r) => r.destination.id == list[index].id,
                  orElse: () => RecommendationResult(
                    destination: list[index],
                    totalScore: 0,
                    scoreBreakdown: {},
                    topActivities: [],
                  ),
                );
                return _buildCarouselCard(result, index + 2); // +2 car rank 1 est en haut
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(RecommendationResult result, int rank) {
    final dest = result.destination;
    final cosineSimilarity = result.totalScore; // 0-100
    final stars = (cosineSimilarity / 100 * 5).clamp(0.0, 5.0); // Convertir en 0-5 étoiles
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(
              destination: dest,
              rank: rank,
              isSerendipity: result.isSerendipity,
              allDestinations: _destinations,
              currentIndex: rank - 1, // rank commence à 1, index à 0
              serendipityIds: _serendipityIds,
            ),
          ),
        ).then((_) => _loadFavorites());
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      'assets/images/destinations/${dest.id}.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: Icon(Icons.landscape, size: 40, color: Colors.white30),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dest.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dest.country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      // Étoiles pour toutes les destinations
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            stars.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
            ),
          ],
        ),
        // Cœur favori en haut à gauche
        if (_favoriteIds.contains(dest.id))
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 16,
              ),
            ),
          ),
        // Badge sérendipité en haut à droite
        if (result.isSerendipity)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.shade900.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
