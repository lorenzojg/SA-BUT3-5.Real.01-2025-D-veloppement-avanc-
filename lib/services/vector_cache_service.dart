import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/destination_v2.dart';
import '../models/destination_vector.dart';
import '../models/user_vector.dart';
import 'database_service_v2.dart';

/// Service de cache des vecteurs précalculés
/// Les vecteurs destinations sont calculés une fois puis stockés en cache
class VectorCacheService {
  static final VectorCacheService _instance = VectorCacheService._internal();
  factory VectorCacheService() => _instance;
  VectorCacheService._internal();

  final DatabaseServiceV2 _db = DatabaseServiceV2();
  
  // Cache en mémoire
  Map<String, DestinationVector>? _cachedDestinationVectors;
  bool _isComputing = false;

  /// Récupère tous les vecteurs destinations (depuis cache ou calcul)
  Future<Map<String, DestinationVector>> getDestinationVectors() async {
    // Si déjà en cache mémoire
    if (_cachedDestinationVectors != null) {
      return _cachedDestinationVectors!;
    }

    // Essayer de charger depuis SharedPreferences
    final cached = await _loadFromStorage();
    if (cached != null && cached.isNotEmpty) {
      print('✅ ${cached.length} vecteurs destinations chargés depuis le cache');
      _cachedDestinationVectors = cached;
      return cached;
    }

    // Sinon, calculer
    return await computeAllDestinationVectors();
  }

  /// Calcule tous les vecteurs destinations (opération lourde)
  /// À appeler en arrière-plan pendant le questionnaire
  Future<Map<String, DestinationVector>> computeAllDestinationVectors({
    bool forceRecompute = false,
  }) async {
    if (_isComputing) {
      print('⏳ Calcul des vecteurs déjà en cours...');
      // Attendre que le calcul en cours se termine
      while (_isComputing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedDestinationVectors ?? {};
    }

    if (!forceRecompute && _cachedDestinationVectors != null) {
      return _cachedDestinationVectors!;
    }

    _isComputing = true;
    print('🔄 Calcul des vecteurs destinations...');
    
    try {
      final destinations = await _db.getAllDestinations();
      final vectors = <String, DestinationVector>{};

      for (final dest in destinations) {
        vectors[dest.id] = _computeDestinationVector(dest);
      }

      print('✅ ${vectors.length} vecteurs destinations calculés');

      // Sauvegarder en cache
      _cachedDestinationVectors = vectors;
      await _saveToStorage(vectors);

      return vectors;
    } finally {
      _isComputing = false;
    }
  }

  /// Calcule le vecteur pour une destination
  DestinationVector _computeDestinationVector(DestinationV2 dest) {
    // Température moyenne sur l'année (normalisée)
    double avgTemp = 0.0;
    int tempCount = 0;
    for (int month = 1; month <= 12; month++) {
      final temp = dest.getAvgTemp(month);
      if (temp != null) {
        avgTemp += temp;
        tempCount++;
      }
    }
    if (tempCount > 0) avgTemp /= tempCount;
    final normalizedTemp = UserVector.normalizeTemperature(avgTemp);

    // Budget
    final normalizedBudget = UserVector.normalizeBudget(dest.getBudgetLevelNumeric());

    // Activity level (de adventure/wellness scores)
    final activityScore = dest.calculateActivityScore() / 100.0; // 0-100 → 0-1

    // Urban level
    final urbanScore = dest.calculateUrbanScore() / 100.0; // 0-100 → 0-1

    // Scores culture/adventure/nature (déjà 0-5)
    final culture = (dest.scoreCulture / 5.0).clamp(0.0, 1.0);
    final adventure = (dest.scoreAdventure / 5.0).clamp(0.0, 1.0);
    final nature = (dest.scoreNature / 5.0).clamp(0.0, 1.0);

    // Continent (one-hot)
    final continentVector = DestinationVector.regionToVector(dest.region);

    return DestinationVector(
      destinationId: dest.id,
      temperature: normalizedTemp,
      budget: normalizedBudget,
      activity: activityScore,
      urban: urbanScore,
      culture: culture,
      adventure: adventure,
      nature: nature,
      continentVector: continentVector,
    );
  }

  /// Sauvegarde les vecteurs en SharedPreferences
  Future<void> _saveToStorage(Map<String, DestinationVector> vectors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir en JSON
      final jsonList = vectors.entries.map((e) => e.value.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString('destination_vectors_cache', jsonString);
      print('💾 Vecteurs sauvegardés en cache');
    } catch (e) {
      print('⚠️ Erreur sauvegarde cache: $e');
    }
  }

  /// Charge les vecteurs depuis SharedPreferences
  Future<Map<String, DestinationVector>?> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('destination_vectors_cache');
      
      if (jsonString == null) return null;
      
      final jsonList = jsonDecode(jsonString) as List;
      final vectors = <String, DestinationVector>{};
      
      for (final json in jsonList) {
        final vector = DestinationVector.fromJson(json);
        vectors[vector.destinationId] = vector;
      }
      
      return vectors;
    } catch (e) {
      print('⚠️ Erreur chargement cache: $e');
      return null;
    }
  }

  /// Invalide le cache (à appeler si les données changent)
  Future<void> invalidateCache() async {
    _cachedDestinationVectors = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('destination_vectors_cache');
    print('🗑️ Cache de vecteurs invalidé');
  }

  /// Lance le précalcul en arrière-plan (non-bloquant)
  void precomputeInBackground() {
    print('🚀 Lancement du précalcul des vecteurs en arrière-plan...');
    computeAllDestinationVectors().then((_) {
      print('✅ Précalcul terminé');
    }).catchError((e) {
      print('❌ Erreur précalcul: $e');
    });
  }
}
