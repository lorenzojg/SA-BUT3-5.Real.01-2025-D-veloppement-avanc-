
import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../services/activity_v2.dart';
import '../services/favorites_service.dart';
import '../services/database_service_v2.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';

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
  final DatabaseServiceV2 _db = DatabaseServiceV2();
  
  bool _isFavorite = false;
  bool _isLoading = true;
  List<ActivityV2> _topActivities = [];
  List<ActivityV2> _allActivities = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _loadActivities();
  }

  Future<void> _loadFavoriteStatus() async {
    await _favoritesService.initialize();
    setState(() {
      _isFavorite = _favoritesService.isFavorite(widget.destination.id);
      _isLoading = false;
    });
  }

  Future<void> _loadActivities() async {
    final activities = await _db.getActivitiesForDestination(widget.destination.id);
    
    // Sélectionner les 3 meilleures activités (par prix puis nom)
    final sorted = List<ActivityV2>.from(activities);
    sorted.sort((a, b) {
      // Priorité: prix bas puis nom
      final priceCompare = a.getPriceLevel().compareTo(b.getPriceLevel());
      if (priceCompare != 0) return priceCompare;
      return a.name.compareTo(b.name);
    });
    
    setState(() {
      _allActivities = activities;
      _topActivities = sorted.take(3).toList();
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

  /// Récupère le prix du vol pour le mois en cours
  String _getFlightPriceForCurrentMonth() {
    final currentMonth = DateTime.now().month; // 1-12
    final price = widget.destination.getFlightPrice(currentMonth);
    
    if (price == null || price == 0) {
      return 'Prix non disponible';
    }
    
    return '${price.toInt()}€';
  }

  /// Récupère la température pour le mois en cours
  String _getCurrentMonthTemperature() {
    final currentMonth = DateTime.now().month; // 1-12
    final temp = widget.destination.getAvgTemp(currentMonth);
    
    if (temp == null) {
      return 'Température non disponible';
    }
    
    return '${temp.toInt()}°C';
  }

  /// Affiche un dialog avec les détails climatiques
  void _showClimateDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a3a52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.amber, size: 30),
              const SizedBox(width: 10),
              const Text(
                'Climat détaillé',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.destination.climatDetails.isNotEmpty) ...[
                  Text(
                    widget.destination.climatDetails,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                ],
                if (widget.destination.periodeRecommendee.isNotEmpty) ...[
                  const Text(
                    'Période recommandée',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.destination.periodeRecommendee,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                ],
                // Températures mensuelles
                const Text(
                  'Températures moyennes par mois',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(12, (index) {
                  final month = index + 1;
                  final monthNames = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                                     'Jui', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
                  final temp = widget.destination.getAvgTemp(month);
                  
                  if (temp == null) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthNames[index],
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${temp.toInt()}°C',
                          style: TextStyle(
                            color: temp > 25 ? Colors.orange : temp > 15 ? Colors.yellow : Colors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Fermer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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
                  // Image de la destination
                  Image.asset(
                    'assets/images/destinations/${widget.destination.id}.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback: dégradé selon le continent avec icône
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getGradientColors(widget.destination.region),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          _getContinentIcon(widget.destination.region),
                          size: 150,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      );
                    },
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
                            widget.destination.city,
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
                                  '${widget.destination.country} • ${widget.destination.region}',
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
                    title: 'À propos de ${widget.destination.city}',
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
                          '${widget.destination.hebergementMoyenEurNuit.toInt()}€ par nuit',
                          widget.destination.budgetLevel,
                          Colors.green,
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          Icons.flight_takeoff,
                          'Prix du vol (ce mois)',
                          _getFlightPriceForCurrentMonth(),
                          'Estimation moyenne',
                          Colors.blue,
                        ),
                        const SizedBox(height: 15),
                        _buildInfoRow(
                          Icons.thermostat,
                          'Température actuelle',
                          _getCurrentMonthTemperature(),
                          'Mois en cours',
                          Colors.orange,
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: _showClimateDetails,
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.wb_sunny, color: Colors.cyan.shade300, size: 22),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Climat détaillé',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Voir plus de détails',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
                              ],
                            ),
                          ),
                        ),
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

                  // ===== ACTIVITÉS RECOMMANDÉES =====
                  if (_topActivities.isNotEmpty) ...[
                    _buildActivitiesSection(),
                    const SizedBox(height: 30),
                  ],

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
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localisation',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.destination.city}, ${widget.destination.country}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Carte du monde avec point rouge
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Carte du monde en arrière-plan
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SimpleMap(
                    instructions: SMapWorld.instructions,
                    defaultColor: Colors.grey.shade300,
                    colors: const {},
                    callback: (id, name, tapdetails) {},
                  ),
                ),
                // Point rouge pour la destination
                Positioned(
                  left: _longitudeToX(widget.destination.longitude),
                  top: _latitudeToY(widget.destination.latitude),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.destination.region} • ${widget.destination.latitude.toStringAsFixed(2)}°, ${widget.destination.longitude.toStringAsFixed(2)}°',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Convertit longitude (-180 à 180) en position X sur la carte (0 à largeur)
  double _longitudeToX(double longitude) {
    // Normaliser longitude: -180 → 0, 0 → 0.5, 180 → 1
    final normalized = (longitude + 180) / 360;
    // Obtenir la largeur du conteneur (approximativement, on utilise la largeur de l'écran moins padding)
    return normalized * (MediaQuery.of(context).size.width - 80) - 8; // -8 pour centrer le point
  }

  /// Convertit latitude (-90 à 90) en position Y sur la carte (0 à hauteur)
  double _latitudeToY(double latitude) {
    // Normaliser latitude: 90 → 0 (haut), 0 → 0.5, -90 → 1 (bas)
    // Projection de Mercator simplifiée
    final normalized = (90 - latitude) / 180;
    return normalized * 150 - 8; // 150 = hauteur de la carte, -8 pour centrer le point
  }

  // ===== CARTE HIGHLIGHT "POURQUOI VISITER" =====
  Widget _buildHighlightCard() {
    // Construire des arguments pertinents basés sur les données réelles
    final arguments = <String>[];
    
    // 1. Climat et période
    if (widget.destination.periodeRecommendee.isNotEmpty) {
      arguments.add('Meilleure période : ${widget.destination.periodeRecommendee}');
    }
    
    // 2. Température actuelle
    final currentMonth = DateTime.now().month;
    final currentTemp = widget.destination.getAvgTemp(currentMonth);
    if (currentTemp != null) {
      final tempEmoji = currentTemp > 25 ? '🔥' : currentTemp > 15 ? '☀️' : '🌤️';
      arguments.add('$tempEmoji Température actuelle : ${currentTemp.toInt()}°C');
    }
    
    // 3. Budget
    final budgetEmoji = widget.destination.budgetLevel == 'Budget' ? '💰' : 
                        widget.destination.budgetLevel == 'Moyen' ? '💵' : '💎';
    arguments.add('$budgetEmoji Budget ${widget.destination.budgetLevel} (${widget.destination.hebergementMoyenEurNuit.toInt()}€/nuit)');
    
    // 4. Type de destination basé sur les scores
    if (widget.destination.scoreNature >= 4) {
      arguments.add('🌿 Destination nature exceptionnelle');
    } else if (widget.destination.scoreCulture >= 4) {
      arguments.add('🏛️ Riche patrimoine culturel');
    } else if (widget.destination.scoreAdventure >= 4) {
      arguments.add('🏔️ Parfait pour l\'aventure');
    }
    
    // 5. Tags principaux
    if (widget.destination.tags.isNotEmpty) {
      final mainTag = widget.destination.tags.first.trim();
      if (mainTag.isNotEmpty) {
        arguments.add('✨ ${mainTag.substring(0, 1).toUpperCase()}${mainTag.substring(1)}');
      }
    }
    
    // 6. Informations pratiques
    if (widget.destination.climatDetails.isNotEmpty && 
        widget.destination.climatDetails.length < 100) {
      arguments.add('🌍 ${widget.destination.climatDetails}');
    }
    
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
          ...arguments.take(4).map((arg) => _buildHighlightPoint(arg)),
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
            Icons.landscape,
            widget.destination.scoreNature.toStringAsFixed(1),
            'Nature',
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.attach_money,
            '${widget.destination.hebergementMoyenEurNuit.toInt()}€',
            'Par nuit',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.directions_run,
            '${widget.destination.scoreAdventure}',
            'Aventure',
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

  // ===== SECTION ACTIVITÉS =====
  Widget _buildActivitiesSection() {
    return _buildSection(
      title: 'Activités recommandées',
      icon: Icons.local_activity,
      iconColor: Colors.purple.shade300,
      child: Column(
        children: [
          // Top 3 activités
          ..._topActivities.map((activity) => _buildActivityCard(activity)),
          
          if (_allActivities.length > 3) ...[
            const SizedBox(height: 16),
            // Bouton "Voir tout"
            OutlinedButton.icon(
              onPressed: () => _showAllActivities(),
              icon: const Icon(Icons.grid_view),
              label: Text('Voir toutes les activités (${_allActivities.length})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityV2 activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône d'activité
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: Colors.purple.shade300,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.type.toUpperCase(),
                  style: TextStyle(
                    color: Colors.purple.shade200,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Prix si disponible
          if (activity.priceRange.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.euro, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    activity.priceRange,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cultural':
      case 'culture':
        return Icons.museum;
      case 'adventure':
      case 'aventure':
        return Icons.hiking;
      case 'nature':
        return Icons.park;
      case 'beach':
      case 'plage':
        return Icons.beach_access;
      case 'food':
      case 'gastronomie':
        return Icons.restaurant;
      case 'nightlife':
        return Icons.nightlife;
      case 'shopping':
        return Icons.shopping_bag;
      case 'wellness':
        return Icons.spa;
      default:
        return Icons.local_activity;
    }
  }

  void _showAllActivities() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a3a52),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Titre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.local_activity, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Toutes les activités (${_allActivities.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            // Liste
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _allActivities.length,
                itemBuilder: (context, index) {
                  return _buildActivityCard(_allActivities[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
