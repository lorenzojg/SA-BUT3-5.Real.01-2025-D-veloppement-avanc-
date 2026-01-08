import 'package:flutter/material.dart';
import '../models/destination_v2.dart';
import '../services/database_service_v2.dart';
import '../services/favorites_service.dart';
import 'destination_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final DatabaseServiceV2 _dbService = DatabaseServiceV2();
  final FavoritesService _favoritesService = FavoritesService();
  
  List<DestinationV2> _favoriteDestinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _favoritesService.initialize();
      
      // Récupérer les IDs des favoris
      final favoriteIds = _favoritesService.getFavoriteIds();
      
      if (favoriteIds.isEmpty) {
        setState(() {
          _favoriteDestinations = [];
          _isLoading = false;
        });
        return;
      }

      // Charger toutes les destinations
      final allDestinations = await _dbService.getAllDestinations();
      
      // Filtrer pour ne garder que les favoris
      final favorites = allDestinations
          .where((dest) => favoriteIds.contains(dest.id))
          .toList();

      setState(() {
        _favoriteDestinations = favorites;
        _isLoading = false;
      });

      print('✅ ${favorites.length} favoris chargés');
    } catch (e) {
      print('❌ Erreur lors du chargement des favoris: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String destinationId) async {
    await _favoritesService.removeFavorite(destinationId);
    await _loadFavorites();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retiré des favoris'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showClearAllDialog() {
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
            'Voulez-vous vraiment supprimer tous vos favoris ?',
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
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _favoritesService.clearAllFavorites();
                await _loadFavorites();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tous les favoris ont été supprimés'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer tout'),
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
        title: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red),
            const SizedBox(width: 10),
            const Text(
              'Mes Favoris',
              style: TextStyle(color: Colors.white),
            ),
            if (_favoriteDestinations.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_favoriteDestinations.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_favoriteDestinations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _showClearAllDialog,
              tooltip: 'Supprimer tous les favoris',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _favoriteDestinations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  color: Colors.blue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _favoriteDestinations.length,
                    itemBuilder: (context, index) {
                      final destination = _favoriteDestinations[index];
                      return _buildFavoriteCard(destination);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 100,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun favori',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ajoutez des destinations à vos favoris pour les retrouver facilement',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explorer les destinations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(DestinationV2 destination) {
    return Dismissible(
      key: Key(destination.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 5),
            Text(
              'Supprimer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a3a52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Retirer des favoris ?',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Voulez-vous retirer "${destination.city}" de vos favoris ?',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
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
      },
      onDismissed: (direction) {
        _removeFavorite(destination.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DestinationDetailPage(
                  destination: destination,
                ),
              ),
            ).then((_) => _loadFavorites()); // Recharger après retour
          },
          borderRadius: BorderRadius.circular(16),
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
                              destination.city,
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
                                Expanded(
                                  child: Text(
                                    '${destination.country} • ${destination.region}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 28,
                        ),
                        onPressed: () => _removeFavorite(destination.id),
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
                        destination.scoreAdventure.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${destination.hebergementMoyenEurNuit.toInt()}€/nuit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    destination.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}