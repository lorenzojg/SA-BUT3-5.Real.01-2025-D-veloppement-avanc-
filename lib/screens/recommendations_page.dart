import 'dart:math';

import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../models/questionnaire_model.dart';
import '../services/database_service.dart';
import '../services/recommendation_service.dart';
import '../services/favorites_service.dart';
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

  List<Destination> _allDestinations = [];
  List<Destination> _destinations = []; // ordered recommendations

  bool _isLoading = true;

  // Favorites
  Set<String> _favoriteIds = {};

  // --- Mini-jeu state ---
  bool _gameStarted = false;
  int _currentRound = 0; // 1..5
  Destination? _currentChoice;
  final Set<String> _gameSeenIds = {}; // éviter répétitions pendant le jeu
  final Set<String> _likedIds = {};
  final Set<String> _dislikedIds = {};

  // Carousel controller
  final ScrollController _carouselController = ScrollController();

  @override
  void initState() {
    super.initState();
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

      // Filtrer / trier via le service existant
      final recommended = RecommendationService.filterAndSortDestinations(
        _allDestinations,
        widget.userPreferences,
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
                    colors: [Colors.blue.shade900, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.travel_explore, size: 60, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 10),
                    const Text('Serendia', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('Votre guide voyage', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  ],
                ),
              ),
              _buildDrawerItem(icon: Icons.home, title: 'Accueil', onTap: () => _navigateToPage('home')),
              const Divider(color: Colors.white24),
              _buildDrawerItem(
                icon: Icons.favorite,
                title: 'Mes Favoris',
                badge: _favoriteIds.isNotEmpty ? _favoriteIds.length : null,
                onTap: () => _navigateToPage('favorites'),
              ),
              _buildDrawerItem(icon: Icons.refresh, title: 'Recommencer', onTap: () => _navigateToPage('reset')),
              _buildDrawerItem(icon: Icons.info_outline, title: 'À propos', onTap: () => _navigateToPage('about')),
              _buildDrawerItem(icon: Icons.email_outlined, title: 'Contactez-nous', onTap: () => _navigateToPage('contact')),
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
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
    if (_destinations.isEmpty) {
      return _buildEmptyStateReplacement();
    }

    final Destination best = _destinations.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meilleure recommandation', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(best.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${best.country} • ${best.continent}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Text(best.description, style: const TextStyle(color: Colors.white, height: 1.4), maxLines: 4, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber.shade700.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
                    child: Text('#1', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                    child: Text('${best.averageCost.toInt()}\$/jour', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(_favoriteIds.contains(best.id) ? Icons.favorite : Icons.favorite_border, color: _favoriteIds.contains(best.id) ? Colors.red : Colors.white),
                    onPressed: () async {
                      await _favoritesService.toggleFavorite(best.id);
                      await _loadFavorites();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_favoriteIds.contains(best.id) ? '💛 Ajouté aux favoris' : 'Retiré des favoris')));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Text('Appuie sur START pour commencer. Pour chaque destination : Like / Dislike / Favoris.',
                style: TextStyle(color: Colors.white.withOpacity(0.8)), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _startGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
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
      _likedIds.clear();
      _dislikedIds.clear();
      _currentChoice = _getRandomUnseenDestination();
      if (_currentChoice != null) _gameSeenIds.add(_currentChoice!.id);
    });
  }

  Widget _buildGameRound() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: compteur et "Favoris"
          Row(
            children: [
              Text('$_currentRound / 5', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('Favoris', style: TextStyle(color: Colors.white.withOpacity(0.9))),
            ],
          ),

          const SizedBox(height: 10),

          // Destination affichée
          Expanded(
            child: _currentChoice == null
                ? Center(child: Text('Aucune destination disponible', style: TextStyle(color: Colors.white70)))
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentChoice!.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${_currentChoice!.country} • ${_currentChoice!.continent}', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(_currentChoice!.description, style: const TextStyle(color: Colors.white, height: 1.3), overflow: TextOverflow.fade),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _currentChoice!.activities.take(4).map((a) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                            child: Text(a, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Bottom row: dislike - fav - like
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dislike
              Column(
                children: [
                  IconButton(
                    onPressed: () => _onUserChoice('dislike'),
                    icon: const Icon(Icons.thumb_down, size: 28, color: Colors.red),
                  ),
                  Text('Dislike', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                ],
              ),

              // Favorite (middle)
              Column(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_currentChoice == null) return;
                      await _favoritesService.toggleFavorite(_currentChoice!.id);
                      await _loadFavorites();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_favoriteIds.contains(_currentChoice!.id) ? '💛 Ajouté aux favoris' : 'Retiré des favoris')));
                      }
                    },
                    icon: Icon(_currentChoice != null && _favoriteIds.contains(_currentChoice!.id) ? Icons.favorite : Icons.favorite_border, size: 32, color: Colors.amber),
                  ),
                  Text('Favoris', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                ],
              ),

              // Like
              Column(
                children: [
                  IconButton(
                    onPressed: () => _onUserChoice('like'),
                    icon: const Icon(Icons.thumb_up, size: 28, color: Colors.green),
                  ),
                  Text('Like', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Traitement d'un like/dislike
  void _onUserChoice(String action) {
    if (_currentChoice == null) return;

    // Envoyer au "backend" (placeholder)
    _sendDecisionToBackend(_currentChoice!, action);

    // Mémoriser localement
    setState(() {
      if (action == 'like') {
        _likedIds.add(_currentChoice!.id);
      } else if (action == 'dislike') {
        _dislikedIds.add(_currentChoice!.id);
      }
    });

    // Snack
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(action == 'like' ? '👍 Liked' : '👎 Disliked')));
    }

    // Avancer
    if (_currentRound >= 5) {
      _finishGameAndRecompute();
    } else {
      setState(() {
        _currentRound++;
        _currentChoice = _getRandomUnseenDestination();
        if (_currentChoice != null) _gameSeenIds.add(_currentChoice!.id);
      });
    }
  }

  void _sendDecisionToBackend(Destination d, String action) {
    // OPTION 3: Placeholder local logging. Remplacer par un appel HTTP ou service quand prêt.
    print('FEEDBACK (placeholder): ${d.id} -> $action');
  }

  Destination? _getRandomUnseenDestination() {
    final candidates = _allDestinations.where((d) => !_gameSeenIds.contains(d.id)).toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle(Random());
    return candidates.first;
  }

  void _finishGameAndRecompute() {
    // Recalculer la recommandation principale en tenant compte des likes/dislikes
    // Stratégie locale simple :
    // - boost des destinations aimées
    // - penalisation des destinations disliked
    // - garder l'ordre original sinon

    final likedSet = _likedIds;
    final dislikedSet = _dislikedIds;

    // Map des scores temporaires
    final Map<String, double> scoreMap = {};

    for (var i = 0; i < _allDestinations.length; i++) {
      final d = _allDestinations[i];
      double base = 0.0;

      // Base: si présent dans _destinations (pré-sélection), on donne un petit boost selon l'index
      final idx = _destinations.indexWhere((e) => e.id == d.id);
      if (idx >= 0) base += (100 - idx.toDouble());

      if (likedSet.contains(d.id)) base += 500; // fort boost si aimé
      if (dislikedSet.contains(d.id)) base -= 250; // pénalité si disliked

      // Ajuster aussi par rating / averageCost / activityScore si nécessaire
      base += d.rating * 10;

      scoreMap[d.id] = base;
    }

    // Trier selon scoreMap
    final newList = List<Destination>.from(_allDestinations);
    newList.sort((a, b) => (scoreMap[b.id] ?? 0).compareTo(scoreMap[a.id] ?? 0));

    setState(() {
      _destinations = newList;
      // reset état du mini-jeu
      _gameStarted = false;
      _currentRound = 0;
      _currentChoice = null;
      _gameSeenIds.clear();
      // note: liked/dislikedIds restent éventuellement sauvegardés pour analytics
    });

    // Retour utilisateur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terminé — recommandations mises à jour')));
    }
  }

  // ---------------- Carousel ----------------
  Widget _buildSimilarDestinationsCarousel() {
    // Exclure la première (main) pour le carrousel
    final list = _destinations.length > 1 ? _destinations.sublist(1) : [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vous pourriez aussi aimer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _scrollCarousel(-300),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                ),
                Expanded(
                  child: list.isEmpty
                      ? Center(child: Text('Pas d\'autres suggestionsns', style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          controller: _carouselController,
                          scrollDirection: Axis.horizontal,
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final d = list[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => DestinationDetailPage(destination: d, rank: index + 2)))
                                    .then((_) => _loadFavorites());
                              },
                              child: Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(d.country, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Text(d.description, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 4, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                IconButton(
                  onPressed: () => _scrollCarousel(300),
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollCarousel(double offset) {
    final newOffset = _carouselController.offset + offset;
    _carouselController.animateTo(
      newOffset.clamp(0.0, _carouselController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }
}
