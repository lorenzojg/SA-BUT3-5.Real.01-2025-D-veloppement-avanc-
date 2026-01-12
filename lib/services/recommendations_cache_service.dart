import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/destination_model.dart';
import '../services/recommendation_service.dart';
import '../services/destination_service.dart';

/// Service de cache pour sauvegarder les recommandations
/// Évite de recalculer à chaque ouverture de l'app
class RecommendationsCacheService {
  static const String _cacheKey = 'cached_recommendations';
  static const String _timestampKey = 'cache_timestamp';
  static const String _serendipityIdsKey = 'cached_serendipity_ids';
  
  // Durée de validité du cache : 24 heures
  static const Duration _cacheValidity = Duration(hours: 24);

  /// Sauvegarde les recommandations en cache
  Future<void> saveRecommendations({
    required List<Destination> destinations,
    required Set<String> serendipityIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les destinations (sous forme de JSON)
      final destJsonList = destinations.map((d) => DestinationService.toMap(d)).toList();
      await prefs.setString(_cacheKey, jsonEncode(destJsonList));
      
      // Sauvegarder les IDs sérendipité
      await prefs.setStringList(_serendipityIdsKey, serendipityIds.toList());
      
      // Sauvegarder le timestamp
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('💾 Cache sauvegardé: ${destinations.length} destinations');
    } catch (e) {
      print('❌ Erreur sauvegarde cache: $e');
    }
  }

  /// Charge les recommandations depuis le cache
  /// Retourne null si le cache est invalide ou expiré
  Future<Map<String, dynamic>?> loadRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier si le cache existe
      if (!prefs.containsKey(_cacheKey) || !prefs.containsKey(_timestampKey)) {
        print('📭 Pas de cache disponible');
        return null;
      }
      
      // Vérifier si le cache est encore valide
      final timestamp = prefs.getInt(_timestampKey)!;
      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      if (now.difference(cacheDate) > _cacheValidity) {
        print('⏰ Cache expiré (${now.difference(cacheDate).inHours}h)');
        await clearCache();
        return null;
      }
      
      // Charger les destinations
      final destJsonString = prefs.getString(_cacheKey);
      if (destJsonString == null) return null;
      
      final destJsonList = jsonDecode(destJsonString) as List;
      final destinations = destJsonList
          .map((json) => Destination.fromMap(json as Map<String, dynamic>))
          .toList();
      
      // Charger les IDs sérendipité
      final serendipityIdsList = prefs.getStringList(_serendipityIdsKey) ?? [];
      final serendipityIds = Set<String>.from(serendipityIdsList);
      
      print('📦 Cache chargé: ${destinations.length} destinations (âge: ${now.difference(cacheDate).inMinutes}min)');
      
      return {
        'destinations': destinations,
        'serendipityIds': serendipityIds,
      };
    } catch (e) {
      print('❌ Erreur chargement cache: $e');
      await clearCache();
      return null;
    }
  }

  /// Efface le cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
      await prefs.remove(_serendipityIdsKey);
      print('🗑️ Cache effacé');
    } catch (e) {
      print('❌ Erreur effacement cache: $e');
    }
  }

  /// Vérifie si un cache valide existe
  Future<bool> hasCachedRecommendations() async {
    final cache = await loadRecommendations();
    return cache != null;
  }
}
