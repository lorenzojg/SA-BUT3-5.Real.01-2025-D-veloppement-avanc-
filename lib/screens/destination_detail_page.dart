import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../services/favorites_service.dart';

class DestinationDetailPage extends StatefulWidget {
  final Destination destination;
  final int? rank;

  const DestinationDetailPage({
    super.key,
    required this.destination,
    this.rank,
  });

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    await _favoritesService.initialize();
    setState(() {
      _isFavorite = _favoritesService.isFavorite(widget.destination.id);
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    await _favoritesService.toggleFavorite(widget.destination.id);
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: _isFavorite ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a3a52),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: CustomScrollView(
        slivers: [
          // ===== APP BAR AVEC IMAGE DE FOND =====
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: const Color(0xFF1a3a52),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Bouton favori dans l'AppBar
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond avec dégradé selon le continent
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getGradientColors(widget.destination.continent),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      _getContinentIcon(widget.destination.continent),
                      size: 150,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  // Gradient overlay pour le texte
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Informations en bas
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge de rang (si disponible)
                          if (widget.rank != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '#${widget.rank} recommandé pour vous',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Nom de la destination
                          Text(
                            widget.destination.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Localisation
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${widget.destination.country} • ${widget.destination.continent}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 4,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== CONTENU DÉFILABLE =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== STATISTIQUES RAPIDES =====
                  _buildQuickStats(),
                  
                  const SizedBox(height: 30),

                  // ===== DESCRIPTION =====
                  _buildSection(
                    title: 'À propos de ${widget.destination.name}',
                    icon: Icons.info_outline,
                    iconColor: Colors.blue.shade300,
                    child: Text(
                      widget.destination.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.7,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== INFORMATIONS PRATIQUES =====
                  _buildSection(
                    title: 'Informations pratiques',
                    icon: Icons.assignment_outlined,
                    iconColor: Colors.orange.shade300,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.attach_money,
                          'Budget quotidien moyen',
                          '${widget.destination.averageCost.toInt()}\$ par jour',
                          _getBudgetLevel(widget.destination.averageCost),
                          Colors.green,
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          Icons.directions_run,
                          'Niveau d\'activité',
                          '${widget.destination.activityScore}/10',
                          _getActivityLevel(widget.destination.activityScore),
                          Colors.orange,
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          Icons.star,
                          'Note des voyageurs',
                          '${widget.destination.rating.toStringAsFixed(1)}/5',
                          _getRatingText(widget.destination.rating),
                          Colors.amber,
                        ),
                        if (widget.destination.unescoSite) ...[
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            Icons.verified,
                            'Patrimoine UNESCO',
                            'Site classé au patrimoine mondial',
                            'Reconnaissance internationale',
                            Colors.amber.shade700,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== POURQUOI VISITER =====
                  _buildHighlightCard(),

                  const SizedBox(height: 30),

                  // ===== CARTE DU CONTINENT =====
                  _buildContinentCard(),

                  const SizedBox(height: 30),

                  // ===== BOUTON FAVORI PRINCIPAL =====
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 24,
                      ),
                      label: Text(
                        _isFavorite 
                            ? 'Retirer des favoris' 
                            : 'Ajouter aux favoris',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFavorite 
                            ? Colors.red.shade600 
                            : Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== CARTE DU CONTINENT =====
  Widget _buildContinentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(widget.destination.continent),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getContinentIcon(widget.destination.continent),
            size: 60,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continent',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.destination.continent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _getContinentDescription(widget.destination.continent),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== CARTE HIGHLIGHT "POURQUOI VISITER" =====
  Widget _buildHighlightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900,
            Colors.purple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade900.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pourquoi visiter ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildHighlightPoint(
            'Destination ${widget.destination.rating >= 4.0 ? "très populaire" : "appréciée"} des voyageurs (${widget.destination.rating.toStringAsFixed(1)}/5)',
          ),
          _buildHighlightPoint(
            'Budget ${_getBudgetLevel(widget.destination.averageCost)} (${widget.destination.averageCost.toInt()}\$/jour)',
          ),
          _buildHighlightPoint(
            'Niveau d\'activité ${widget.destination.activityScore}/10 - ${_getActivityLevel(widget.destination.activityScore)}',
          ),
          if (widget.destination.unescoSite)
            _buildHighlightPoint(
              'Site classé au patrimoine mondial de l\'UNESCO',
            ),
          _buildHighlightPoint(
            'Idéal pour découvrir ${widget.destination.continent}',
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== STATISTIQUES RAPIDES =====
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.star,
            widget.destination.rating.toStringAsFixed(1),
            'Note',
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.attach_money,
            '${widget.destination.averageCost.toInt()}\$',
            'Par jour',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.directions_run,
            '${widget.destination.activityScore}',
            'Activité',
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== SECTION GÉNÉRIQUE =====
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        child,
      ],
    );
  }

  // ===== LIGNE D'INFORMATION =====
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== FONCTIONS UTILITAIRES =====

  // Couleurs de dégradé selon le continent
  List<Color> _getGradientColors(String continent) {
    switch (continent.toLowerCase()) {
      case 'afrique':
        return [Colors.orange.shade800, Colors.orange.shade600];
      case 'amérique du nord':
        return [Colors.blue.shade900, Colors.blue.shade700];
      case 'amérique du sud':
        return [Colors.green.shade900, Colors.green.shade700];
      case 'asie':
        return [Colors.red.shade900, Colors.red.shade700];
      case 'europe':
        return [Colors.indigo.shade900, Colors.indigo.shade700];
      case 'océanie':
        return [Colors.cyan.shade900, Colors.cyan.shade700];
      default:
        return [Colors.blue.shade900, Colors.blue.shade700];
    }
  }

  // Icône selon le continent
  IconData _getContinentIcon(String continent) {
    switch (continent.toLowerCase()) {
      case 'afrique':
        return Icons.terrain;
      case 'amérique du nord':
        return Icons.apartment;
      case 'amérique du sud':
        return Icons.forest;
      case 'asie':
        return Icons.temple_buddhist;
      case 'europe':
        return Icons.castle;
      case 'océanie':
        return Icons.waves;
      default:
        return Icons.public;
    }
  }

  // Description du continent
  String _getContinentDescription(String continent) {
    switch (continent.toLowerCase()) {
      case 'afrique':
        return 'Terre de safaris et de diversité';
      case 'amérique du nord':
        return 'Mégalopoles et grands espaces';
      case 'amérique du sud':
        return 'Nature luxuriante et culture vibrante';
      case 'asie':
        return 'Traditions millénaires et modernité';
      case 'europe':
        return 'Histoire, art et gastronomie';
      case 'océanie':
        return 'Paradis tropicaux et aventures';
      default:
        return 'Destination mondiale';
    }
  }

  // Niveau de budget
  String _getBudgetLevel(double cost) {
    if (cost < 50) return 'économique';
    if (cost < 100) return 'modéré';
    if (cost < 200) return 'confortable';
    return 'élevé';
  }

  // Niveau d'activité
  String _getActivityLevel(int score) {
    if (score <= 3) return 'Détente et relaxation';
    if (score <= 5) return 'Rythme modéré';
    if (score <= 7) return 'Assez actif';
    return 'Très actif';
  }

  // Texte de la note
  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Très bien';
    if (rating >= 3.5) return 'Bien';
    if (rating >= 3.0) return 'Correct';
    return 'À améliorer';
  }
}