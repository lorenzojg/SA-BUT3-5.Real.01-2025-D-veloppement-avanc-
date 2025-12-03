import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  static const String _favoritesKey = 'user_favorites';

  // Singleton pattern
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  // Liste des IDs des destinations favorites
  Set<String> _favoriteIds = {};
  bool _isInitialized = false;

  // Initialiser le service (charger les favoris depuis le stockage)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson != null) {
      try {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        _favoriteIds = favoritesList.map((e) => e.toString()).toSet();
      } catch (e) {
        print('❌ Erreur lors du chargement des favoris: $e');
        _favoriteIds = {};
      }
    }
    
    _isInitialized = true;
    print('✅ Favoris chargés: ${_favoriteIds.length} destinations');
  }

  // Sauvegarder les favoris
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = json.encode(_favoriteIds.toList());
    await prefs.setString(_favoritesKey, favoritesJson);
  }

  // Ajouter aux favoris
  Future<void> addFavorite(String destinationId) async {
    await initialize();
    _favoriteIds.add(destinationId);
    await _saveFavorites();
    print('💛 Ajouté aux favoris: $destinationId');
  }

  // Retirer des favoris
  Future<void> removeFavorite(String destinationId) async {
    await initialize();
    _favoriteIds.remove(destinationId);
    await _saveFavorites();
    print('🤍 Retiré des favoris: $destinationId');
  }

  // Basculer favori (toggle)
  Future<void> toggleFavorite(String destinationId) async {
    if (isFavorite(destinationId)) {
      await removeFavorite(destinationId);
    } else {
      await addFavorite(destinationId);
    }
  }

  // Vérifier si une destination est favorite
  bool isFavorite(String destinationId) {
    return _favoriteIds.contains(destinationId);
  }

  // Obtenir tous les IDs des favoris
  Set<String> getFavoriteIds() {
    return Set.from(_favoriteIds);
  }

  // Obtenir le nombre de favoris
  int getFavoritesCount() {
    return _favoriteIds.length;
  }

  // Effacer tous les favoris
  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    await _saveFavorites();
    print('🗑️ Tous les favoris ont été supprimés');
  }
}