import 'dart:math';
import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../models/user_interaction_model.dart';
import '../models/user_profile_vector.dart';
import '../services/database_service.dart';
import '../services/recommendation_service.dart';
import '../services/enhanced_recommendation_service.dart';
import '../services/favorites_service.dart';
import '../services/user_interaction_service.dart';
import 'contact_page.dart';
import 'about_page.dart';
import 'reset_preferences_page.dart';
import 'favorites_page.dart';
import 'destination_detail_page.dart';

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
  final FavoritesService _favoritesService = FavoritesService();
  final EnhancedRecommendationService _enhancedService = EnhancedRecommendationService();

  List<Destination> _allDestinations = [];
  List<Destination> _destinations = []; // ordered recommendations
  
  // Profil utilisateur dynamique (évolue avec les interactions)
  late UserProfileVector _currentUserProfile;

  bool _isLoading = true;

  // Favorites
  Set<String> _favoriteIds = {};

  // --- Mini-jeu state ---
  bool _gameStarted = false;
  int _currentRound = 0; // 1..5
  Destination? _currentChoice;
  final Set<String> _gameSeenIds = {}; // éviter répétitions pendant le jeu
  
  // Pour mesurer le temps de réaction (Interaction Duration)
  DateTime? _cardShownTime;

  // Carousel controller
  final ScrollController _carouselController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialisation du profil vectoriel à partir des réponses statiques
    _currentUserProfile = RecommendationService.createVectorFromPreferences(widget.userPreferences);
    
    // Initialiser le service enrichi
    _enhancedService.initialize(preferences: widget.userPreferences);

    _loadRecommendations();
    _loadFavorites();
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

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    try {
      _allDestinations = await _dbService.getAllDestinations();

      // Utilisation de l'algorithme de recommandation enrichi
      final recommended = await _enhancedService.getEnhancedRecommendations(
        _allDestinations,
        limit: 20,
      );

      setState(() {
        _destinations = recommended;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement destinations: $e');
      setState(() => _isLoading = false);
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

  String _getBudgetLevel(double cost) {
    if (cost < 100) return '€';
    if (cost < 200) return '€€';
    return '€€€';
  }

  // ---------------- Main Recommendation ----------------
  Widget _buildMainRecommendation() {
    if (_destinations.isEmpty) {
      return _buildEmptyStateReplacement();
    }

    final Destination best = _destinations.first;
    final isFavorite = _favoriteIds.contains(best.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(destination: best, rank: 1),
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
            Text(
              best.name,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              '${best.continent}, ${best.country}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTag(Icons.euro, _getBudgetLevel(best.averageCost)),
                const SizedBox(width: 10),
                _buildTag(
                  Icons.wb_sunny, 
                  best.climate.length > 20 
                      ? '${best.climate.substring(0, 17)}...' 
                      : best.climate
                ),
                const SizedBox(width: 10),
                _buildTag(Icons.star, best.rating.toString()),
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
                      builder: (context) => DestinationDetailPage(destination: best, rank: 1),
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
    if (_allDestinations.isEmpty) return;

    setState(() {
      _gameStarted = true;
      _currentRound = 1;
      _gameSeenIds.clear();
      _currentChoice = _getRandomUnseenDestination();
      if (_currentChoice != null) {
        _gameSeenIds.add(_currentChoice!.id);
        _cardShownTime = DateTime.now(); // Start timer
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
                    // Log interaction for favorite
                    _logInteraction(InteractionType.addToFavorites);
                  }
                  _loadFavorites();
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Destination affichée
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_city, size: 40, color: Colors.white70),
                  const SizedBox(height: 10),
                  Text(dest.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(dest.country, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      Chip(label: Text(_getBudgetLevel(dest.averageCost)), backgroundColor: Colors.white10, labelStyle: const TextStyle(color: Colors.white)),
                      Chip(label: Text(dest.climate), backgroundColor: Colors.white10, labelStyle: const TextStyle(color: Colors.white)),
                    ],
                  )
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

    // 1. Log Interaction & Update Profile
    final type = action == 'like' ? InteractionType.like : InteractionType.dislike;
    await _logInteraction(type);

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
      _finishGameAndRecompute();
    } else {
      setState(() {
        _currentRound++;
        _currentChoice = _getRandomUnseenDestination();
        if (_currentChoice != null) {
          _gameSeenIds.add(_currentChoice!.id);
          _cardShownTime = DateTime.now(); // Reset timer
        }
      });
    }
  }

  Future<void> _logInteraction(InteractionType type) async {
    if (_currentChoice == null) return;

    final duration = _cardShownTime != null 
        ? DateTime.now().difference(_cardShownTime!).inMilliseconds 
        : 1000;

    final interaction = UserInteraction(
      destinationId: _currentChoice!.id,
      type: type,
      timestamp: DateTime.now(),
      durationMs: duration,
    );

    // 1. Sauvegarde en BDD via le service enrichi (qui gère aussi l'historique pour l'algo)
    await _enhancedService.recordInteraction(_currentChoice!.id, type);

    // 2. Mise à jour du profil utilisateur en mémoire (Apprentissage local pour affichage ou autre)
    setState(() {
      _currentUserProfile = UserInteractionService.updateUserProfile(
        _currentUserProfile,
        _currentChoice!,
        interaction,
      );
    });
  }

  Destination? _getRandomUnseenDestination() {
    final candidates = _allDestinations.where((d) => !_gameSeenIds.contains(d.id)).toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle(Random());
    return candidates.first;
  }

  Future<void> _finishGameAndRecompute() async {
    // Recalculer la recommandation principale en tenant compte du profil mis à jour
    // On recharge via le service enrichi qui a pris en compte les interactions
    await _loadRecommendations();

    setState(() {
      _gameStarted = false;
      _currentRound = 0;
      _currentChoice = null;
      _gameSeenIds.clear();
    });

    // Retour utilisateur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci ! Vos recommandations ont été affinées.'),
          backgroundColor: Colors.green,
        )
      );
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
                final dest = list[index];
                return _buildCarouselCard(dest, index + 2); // +2 car rank 1 est en haut
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(Destination dest, int rank) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(destination: dest, rank: rank),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(Icons.landscape, size: 40, color: Colors.white30),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.name,
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
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(dest.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
