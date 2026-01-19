import 'dart:math';
import '../services/destination_service.dart';
import '../services/activity_service.dart';
import '../models/destination_model.dart';
import '../models/activity_model.dart';
import '../models/user_preferences_model.dart';
import '../models/user_vector_model.dart';
import '../models/destination_vector_model.dart';
import 'vector_distance_service.dart';
import 'vector_cache_service.dart';
import 'recent_bias_service.dart';
import 'performance_profiler.dart';

/// Résultat de recommandation avec le score détaillé
class RecommendationResult {
  final Destination destination;
  double totalScore; // Non final pour permettre la mise à jour après calcul bonus
  final Map<String, double> scoreBreakdown;
  final List<Activity> topActivities;
  final bool isSerendipity; // Flag pour indiquer si c'est une recommandation sérendipité

  RecommendationResult({
    required this.destination,
    required this.totalScore,
    required this.scoreBreakdown,
    required this.topActivities,
    this.isSerendipity = false,
  });
}

/// Service de recommandation
class RecommendationServiceV2 {
  static final RecommendationServiceV2 _instance = RecommendationServiceV2._internal();
  factory RecommendationServiceV2() => _instance;
  RecommendationServiceV2._internal();

  final DestinationService _destinationService = DestinationService();
  final ActivityService _activityService = ActivityService();

  /// Point d'entrée principal: recommande des destinations
  /// 
  /// [prefs] Préférences utilisateur du questionnaire
  /// [limit] Nombre de destinations à retourner
  /// [includeActivities] Charger les activités pour affiner le score
  Future<List<RecommendationResult>> getRecommendations({
    required UserPreferencesV2 prefs,
    int limit = 10,
    bool includeActivities = true,
  }) async {
    print('🎯 === DEBUT getRecommendations() ===');
    print('   Préférences: continents=${prefs.selectedContinents}, budget=${prefs.budgetLevel}');
    
    // 1. Charger toutes les destinations
    final allDestinations = await _destinationService.getAllDestinations();

    // 2. Filtrer les destinations inadmissibles
    final eligibleDestinations = _filterEligibleDestinations(
      allDestinations,
      prefs,
    );
    print('✅ ${eligibleDestinations.length} destinations éligibles');

    // 3. Scorer chaque destination éligible
    final results = <RecommendationResult>[];
    for (final destination in eligibleDestinations) {
      final score = await _scoreDestination(
        destination,
        prefs,
        includeActivities: includeActivities,
      );
      results.add(score);
    }

    // 4. Trier par score décroissant
    results.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // 5. Retourner le top N
    return results.take(limit).toList();
  }

  /// Filtre les destinations non éligibles (filtres stricts)
  List<Destination> _filterEligibleDestinations(
    List<Destination> destinations,
    UserPreferencesV2 prefs,
  ) {
    print('🔍 === FILTRAGE DES DESTINATIONS ===');
    print('   📍 ${destinations.length} destinations à filtrer');
    print('   🌍 Continents demandés: ${prefs.selectedContinents.join(", ")}');
    print('   💰 Budget: ${prefs.budgetLevel}/4');
    print('   🌡️ Temp min: ${prefs.minTemperature}°C');
    
    int filteredByContinent = 0;
    int filteredByTemp = 0;
    int filteredByBudget = 0;
    
    // Afficher quelques régions pour debug
    final uniqueRegions = destinations.map((d) => d.region).toSet().toList();
    print('   🗺️ Régions disponibles: ${uniqueRegions.take(10).join(", ")}${uniqueRegions.length > 10 ? "..." : ""}');
    
    final filtered = destinations.where((dest) {
      // Filtre 1: Continent
      if (prefs.selectedContinents.isNotEmpty) {
        bool matchesContinent = false;
        for (final continent in prefs.selectedContinents) {
          if (DestinationService.matchesContinent(dest, continent)) {
            matchesContinent = true;
            break;
          }
        }
        if (!matchesContinent) {
          filteredByContinent++;
          return false;
        }
      }

      // Filtre 2: Budget (écart max de ±1 niveaux)
      final destBudget = DestinationService.getBudgetLevelNumeric(dest);
      if ((destBudget - prefs.budgetLevel).abs() > 1.0) {
        filteredByBudget++;
        return false;
      }

      return true;
    }).toList();
    
    print('   ✅ ${filtered.length} destinations éligibles');
    print('   ❌ Filtrées: $filteredByContinent (continent), $filteredByTemp (temp), $filteredByBudget (budget)');
    
    return filtered;
  }

  /// Calcule le score total d'une destination
  Future<RecommendationResult> _scoreDestination(
    Destination destination,
    UserPreferencesV2 prefs, {
    required bool includeActivities,
  }) async {
    final breakdown = <String, double>{};
    double totalScore = 0.0;

    // === 1. Score de Climat (0-25 points) ===
    final climateScore = _calculateClimateScore(destination, prefs);
    breakdown['Climat'] = climateScore;
    totalScore += climateScore;

    // === 2. Score de Budget (0-20 points) ===
    final budgetScore = _calculateBudgetScore(destination, prefs);
    breakdown['Budget'] = budgetScore;
    totalScore += budgetScore;

    // === 3. Score d'Activité (0-20 points) ===
    final activityScore = _calculateActivityMatchScore(destination, prefs);
    breakdown['Activité'] = activityScore;
    totalScore += activityScore;

    // === 4. Score Urbain/Nature (0-15 points) ===
    final urbanScore = _calculateUrbanMatchScore(destination, prefs);
    breakdown['Urbain/Nature'] = urbanScore;
    totalScore += urbanScore;

    // === 5. Score des Activités (0-15 points) ===
    List<Activity> topActivities = [];
    if (includeActivities) {
      final activitiesScore = await _calculateActivitiesScore(
        destination,
        prefs,
      );
      breakdown['Activités'] = activitiesScore['score']!;
      totalScore += activitiesScore['score']!;
      topActivities = activitiesScore['activities'] as List<Activity>;
    }

    // === 6. Bonus Prix Vol (0-5 points) ===
    final flightBonus = _calculateFlightPriceBonus(destination, prefs);
    breakdown['Prix Vol'] = flightBonus;
    totalScore += flightBonus;

    return RecommendationResult(
      destination: destination,
      totalScore: totalScore,
      scoreBreakdown: breakdown,
      topActivities: topActivities,
    );
  }

  // === Fonctions de scoring détaillées ===

  /// Score de climat (0-25 points)
  /// Favorise les destinations avec une température proche de la préférence
  /// Système permissif: toutes les destinations ont un score (pas de filtrage binaire)
  double _calculateClimateScore(Destination dest, UserPreferencesV2 prefs) {
    final month = prefs.travelMonth ?? DateTime.now().month;
    final avgTemp = DestinationService.getAvgTemp(dest, month);
    
    if (avgTemp == null) return 12.5; // Score neutre si pas de données

    // Température idéale = minTemperature de l'utilisateur
    final idealTemp = prefs.minTemperature;
    final tempDiff = (avgTemp - idealTemp).abs();

    // Système de scoring permissif avec courbe gaussienne
    // Score max (25 pts) si différence < 5°C
    // Décroît progressivement jusqu'à 20°C de différence
    if (tempDiff <= 5) {
      return 25.0; // Match parfait
    } else if (tempDiff <= 10) {
      return 25.0 - (tempDiff - 5) * 2.0; // 25 → 15 pts
    } else if (tempDiff <= 20) {
      return 15.0 - (tempDiff - 10) * 1.0; // 15 → 5 pts
    } else {
      return max(0.0, 5.0 - (tempDiff - 20) * 0.5); // 5 → 0 pts
    }
  }

  /// Score de budget (0-20 points)
  /// Favorise les destinations correspondant au budget
  double _calculateBudgetScore(Destination dest, UserPreferencesV2 prefs) {
    final destBudget = DestinationService.getBudgetLevelNumeric(dest);
    final budgetDiff = (destBudget - prefs.budgetLevel).abs();

    // Score max si même niveau, décroît avec la différence
    if (budgetDiff == 0) {
      return 20.0;
    } else if (budgetDiff <= 1) {
      return 15.0;
    } else if (budgetDiff <= 2) {
      return 10.0;
    } else {
      return 5.0;
    }
  }

  /// Score d'activité (0-20 points)
  /// Compare le niveau d'activité de la destination avec la préférence
  double _calculateActivityMatchScore(Destination dest, UserPreferencesV2 prefs) {
    final destActivityLevel = DestinationService.calculateActivityScore(dest);
    final diff = (destActivityLevel - prefs.activityLevel).abs();

    // Score max si différence < 10, décroît ensuite
    if (diff <= 10) {
      return 20.0;
    } else if (diff <= 25) {
      return 20.0 - (diff - 10) * 0.5;
    } else {
      return max(0.0, 20.0 - diff * 0.3);
    }
  }

  /// Score urbain/nature (0-15 points)
  /// Compare la préférence urbain/nature avec la destination
  double _calculateUrbanMatchScore(Destination dest, UserPreferencesV2 prefs) {
    final destUrbanLevel = DestinationService.calculateUrbanScore(dest);
    final diff = (destUrbanLevel - prefs.urbanLevel).abs();

    // Score max si différence < 15, décroît ensuite
    if (diff <= 15) {
      return 15.0;
    } else if (diff <= 30) {
      return 15.0 - (diff - 15) * 0.5;
    } else {
      return max(0.0, 15.0 - diff * 0.2);
    }
  }

  /// Score des activités (0-15 points)
  /// Analyse les activités liées à la destination
  Future<Map<String, dynamic>> _calculateActivitiesScore(
    Destination dest,
    UserPreferencesV2 prefs,
  ) async {
    final activities = await _activityService.getActivitiesForDestination(dest.id);
    
    if (activities.isEmpty) {
      return {'score': 7.5, 'activities': <Activity>[]};
    }

    // Calculer le match moyen des activités
    int matchCount = 0;
    final matchingActivities = <Activity>[];

    for (final activity in activities) {
      final activityMatch = ActivityService.matchesActivityLevel(activity, prefs.activityLevel);
      final urbanMatch = ActivityService.matchesUrbanLevel(activity, prefs.urbanLevel);
      
      if (activityMatch && urbanMatch) {
        matchCount++;
        matchingActivities.add(activity);
      }
    }

    // Score basé sur le pourcentage de match
    final matchRatio = matchCount / activities.length;
    final score = matchRatio * 15.0;

    // Trier les activités par pertinence et garder le top 5
    final topActivities = matchingActivities.take(5).toList();

    return {'score': score, 'activities': topActivities};
  }

  /// Bonus pour le prix du vol (0-5 points)
  /// Favorise les mois avec des vols moins chers
  double _calculateFlightPriceBonus(Destination dest, UserPreferencesV2 prefs) {
    final month = prefs.travelMonth ?? DateTime.now().month;
    final flightPrice = DestinationService.getFlightPrice(dest, month);
    
    if (flightPrice == null) return 2.5;

    // Bonus inversement proportionnel au prix
    // Prix < 500€ = 5 pts, 500-1000€ = 3 pts, > 1000€ = 1 pt
    if (flightPrice < 500) {
      return 5.0;
    } else if (flightPrice < 1000) {
      return 3.0;
    } else if (flightPrice < 1500) {
      return 1.5;
    } else {
      return 0.5;
    }
  }

  /// Statistiques de recommandation
  Map<String, dynamic> getRecommendationStats(List<RecommendationResult> results) {
    if (results.isEmpty) {
      return {
        'count': 0,
        'avgScore': 0.0,
        'topContinent': 'N/A',
        'avgBudget': 'N/A',
      };
    }

    final avgScore = results.map((r) => r.totalScore).reduce((a, b) => a + b) / results.length;
    
    final continents = <String, int>{};
    for (final result in results) {
      final region = result.destination.region;
      continents[region] = (continents[region] ?? 0) + 1;
    }
    
    final topContinent = continents.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final budgets = results.map((r) => r.destination.budgetLevel).toList();
    final avgBudget = budgets.isNotEmpty ? budgets.first : 'N/A';

    return {
      'count': results.length,
      'avgScore': avgScore.toStringAsFixed(1),
      'topContinent': topContinent,
      'avgBudget': avgBudget,
    };
  }

  /// Obtient des destinations diversifiées pour le mini-jeu
  /// Permet d'explorer au-delà des préférences initiales pour affiner le profil
  /// 
  /// [prefs] Préférences actuelles (utilisées pour le scoring mais pas le filtrage de continent)
  /// [limit] Nombre de destinations à retourner
  /// 
  /// Retourne un mix de destinations:
  /// - 40% des continents sélectionnés
  /// - 60% d'autres continents (pour découverte)
  Future<List<Destination>> getDiverseDestinationsForGame({
    required UserPreferencesV2 prefs,
    int limit = 20,
  }) async {
    print('🎮 === CHARGEMENT DESTINATIONS POUR MINI-JEU ===');
    
    // Charger TOUTES les destinations (sans filtre de continent)
    final allDestinations = await DestinationService().getAllDestinations();
    print('   📍 ${allDestinations.length} destinations disponibles');
    
    if (allDestinations.isEmpty) return [];

    // Filtrer seulement par budget (tolérance large)
    final budgetFiltered = allDestinations.where((dest) {
      final destBudget = DestinationService.getBudgetLevelNumeric(dest);
      return (destBudget - prefs.budgetLevel).abs() <= 3.0; // Très permissif
    }).toList();
    
    print('   💰 ${budgetFiltered.length} destinations après filtre budget souple');

    // Séparer destinations des continents sélectionnés vs autres
    final fromSelectedContinents = <Destination>[];
    final fromOtherContinents = <Destination>[];
    
    for (final dest in budgetFiltered) {
      bool isFromSelected = false;
      for (final continent in prefs.selectedContinents) {
        if (DestinationService.matchesContinent(dest, continent)) {
          isFromSelected = true;
          break;
        }
      }
      
      if (isFromSelected) {
        fromSelectedContinents.add(dest);
      } else {
        fromOtherContinents.add(dest);
      }
    }
    
    print('   🌍 ${fromSelectedContinents.length} de vos continents, ${fromOtherContinents.length} d\'ailleurs');

    // Mélanger
    fromSelectedContinents.shuffle(Random());
    fromOtherContinents.shuffle(Random());

    // Composer le mix: 40% sélectionnés, 60% autres
    final selectedCount = (limit * 0.4).round();
    final otherCount = limit - selectedCount;
    
    final result = <Destination>[];
    result.addAll(fromSelectedContinents.take(selectedCount));
    result.addAll(fromOtherContinents.take(otherCount));
    
    // Re-mélanger le résultat final
    result.shuffle(Random());
    
    print('   ✅ ${result.length} destinations sélectionnées pour le jeu (mix diversifié)');
    return result;
  }

  // ============================================================================
  // SYSTÈME VECTORIEL (Nouveau)
  // ============================================================================

  final VectorDistanceService _vectorService = VectorDistanceService();
  final VectorCacheService _cacheService = VectorCacheService();
  final RecentBiasService _biasService = RecentBiasService();

  /// Recommandations basées sur la distance vectorielle OPTIMISÉE
  /// 
  /// Nouvelle approche :
  /// 1. Trouver 2 destinations en mode sérendipité
  /// 2. Calculer un poids pour chaque continent basé sur la proximité du vecteur utilisateur
  /// 3. Répartir les calculs selon ces poids (évite de calculer sur toute la base)
  /// 4. Garantit la diversité continentale
  /// 
  /// [prefs] Préférences utilisateur
  /// [limit] Nombre de résultats
  /// [serendipityRatio] Pourcentage de destinations en mode sérendipité (0.0-1.0)
  /// [includeRecentBias] Activer l'effet de mode court terme
  /// [continentOnlySerendipity] Si true, la sérendipité inverse UNIQUEMENT le continent (mini-jeu)
  /// [excludeIds] IDs de destinations à exclure (pour éviter les doublons)
  /// 
  /// Retourne les destinations triées par similarité cosinus
  Future<List<RecommendationResult>> getRecommendationsVectorBased({
    required UserPreferencesV2 prefs,
    int limit = 10,
    double serendipityRatio = 0.1,  // 10% par défaut
    bool includeRecentBias = true,
    bool continentOnlySerendipity = false,
    Set<String>? excludeIds,
    PerformanceProfiler? profiler, // Nouveau paramètre
  }) async {
    print('🎯 === RECOMMANDATIONS VECTORIELLES OPTIMISÉES ===');
    print('   Sérendipité: ${(serendipityRatio * 100).toStringAsFixed(0)}%');
    if (excludeIds != null && excludeIds.isNotEmpty) {
      print('   🚫 Exclusions: ${excludeIds.length} destinations');
    }
    
    // 🎯 Démarrer l'enregistrement si profiler fourni
    if (profiler != null) {
      await profiler.startRecording();
    }
    
    try {
      // 1. Convertir préférences en vecteur
      UserVector userVector = prefs.toVector();
      print('   📐 Vecteur utilisateur: $userVector');
      
      // 2. Appliquer effet de mode court terme
      if (includeRecentBias) {
        userVector = _biasService.applyRecentBias(userVector);
      }
    
      // 3. Charger les destinations et vecteurs
      final allDestVectors = await _cacheService.getDestinationVectors();
      final allDestinations = await _destinationService.getAllDestinations();
      final destMap = {for (var d in allDestinations) d.id: d};
      
      // Filtrer les exclusions
      final availableDestVectors = excludeIds != null
          ? Map.fromEntries(
              allDestVectors.entries.where((e) => !excludeIds.contains(e.key))
            )
          : allDestVectors;
      
      print('   📊 ${availableDestVectors.length} destinations disponibles');
      
      // === ÉTAPE 1 : Trouver 2 destinations sérendipité ===
      final serendipityCount = max(2, (limit * serendipityRatio).round());
      print('   🎲 Recherche de $serendipityCount destinations sérendipité...');
      
      final serendipityResults = await _computeVectorDistances(
        userVector: userVector,
        destVectors: availableDestVectors,
        enableSerendipity: true,
        continentOnly: continentOnlySerendipity,
        limit: serendipityCount,
        profiler: profiler,
        stepPrefix: 'Sérendipité',
      );
      
      final usedIds = serendipityResults.map((r) => r.destination.id).toSet();
      print('   ✓ ${serendipityResults.length} sérendipité trouvées');
      
      // === ÉTAPE 2 : Filtrer par continent des préférences ===
      final remainingSlots = limit - serendipityResults.length;
      print('   📍 $remainingSlots places restantes à répartir...');
      
      if (prefs.selectedContinents.isEmpty || remainingSlots <= 0) {
        final result = serendipityResults.take(limit).toList();
        
        if (profiler != null) {
          await profiler.stopRecording(version: '1.0');
        }
        
        return result;
      }
      
      // Grouper destinations disponibles par continent
      final byContinentVectors = <String, Map<String, DestinationVector>>{};
      for (final continent in prefs.selectedContinents) {
        byContinentVectors[continent] = {};
      }
      
      for (final entry in availableDestVectors.entries) {
        final destId = entry.key;
        if (usedIds.contains(destId)) continue; // Skip sérendipité
        
        final dest = destMap[destId];
        if (dest == null) continue;
        
        for (final continent in prefs.selectedContinents) {
          if (DestinationService.matchesContinent(dest, continent)) {
            byContinentVectors[continent]![destId] = entry.value;
            break;
          }
        }
      }
      
      // Afficher la répartition
      for (final entry in byContinentVectors.entries) {
        print('   ${entry.key}: ${entry.value.length} destinations');
      }
      
      // === ÉTAPE 3 : Calculer les poids par continent (depuis le vecteur utilisateur) ===
      final weights = _calculateContinentWeights(
        userVector,
        prefs.selectedContinents,
      );
      
      print('   ⚖️ Poids des continents:');
      for (final entry in weights.entries) {
        print('      ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%');
      }
      
      // === ÉTAPE 4 : Calculer les meilleures destinations par continent ===
      final continentResults = <String, List<RecommendationResult>>{};
      
      // Commencer par le continent avec le PLUS FAIBLE poids (comme demandé)
      final sortedContinents = weights.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value)); // Croissant
      
      for (final entry in sortedContinents) {
        final continent = entry.key;
        final weight = entry.value;
        final continentVectors = byContinentVectors[continent]!;
        
        if (continentVectors.isEmpty) {
          continentResults[continent] = [];
          continue;
        }
        
        // Nombre de destinations à prendre (arrondi au supérieur)
        final targetCount = (weight * remainingSlots).ceil();
        print('   🔍 $continent: calcul sur ${continentVectors.length} destinations (cible: $targetCount)...');
        
        // Calculer distances UNIQUEMENT pour ce continent
        final results = await _computeVectorDistances(
          userVector: userVector,
          destVectors: continentVectors,
          enableSerendipity: false,
          continentOnly: false,
          limit: targetCount,
          profiler: profiler,
          stepPrefix: continent,
        );
        
        continentResults[continent] = results;
        print('   ✓ ${results.length} résultats pour $continent');
      }
      
      // === ÉTAPE 5 : Combiner avec round-robin ===
      final normalResults = <RecommendationResult>[];
      final iterators = <String, int>{};
      for (final continent in prefs.selectedContinents) {
        iterators[continent] = 0;
      }
      
      // Round-robin jusqu'à atteindre le nombre voulu
      while (normalResults.length < remainingSlots) {
        bool addedAny = false;
        
        for (final continent in prefs.selectedContinents) {
          if (normalResults.length >= remainingSlots) break;
          
          final results = continentResults[continent]!;
          final index = iterators[continent]!;
          
          if (index < results.length) {
            normalResults.add(results[index]);
            iterators[continent] = index + 1;
            addedAny = true;
          }
        }
        
        if (!addedAny) break; // Plus de destinations disponibles
      }
      
      print('   ✓ ${normalResults.length} destinations normales collectées');
      
      // === ÉTAPE 6 : Combiner sérendipité + normales ===
      final combined = <RecommendationResult>[
        ...serendipityResults,
        ...normalResults,
      ];
      
      // Mélanger légèrement (garder top 3)
      if (combined.length > 3) {
        final top3 = combined.take(3).toList();
        final rest = combined.skip(3).toList();
        rest.shuffle(Random());
        combined.clear();
        combined.addAll(top3);
        combined.addAll(rest);
      }
      
      print('   ✅ ${combined.length} recommandations générées (optimisées)');
      
      final result = combined.take(limit).toList();
      
      // 🎯 Arrêter l'enregistrement si profiler fourni
      if (profiler != null) {
        await profiler.stopRecording(version: '1.0');
      }
      
      return result;
    } catch (e) {
      // En cas d'erreur, arrêter quand même l'enregistrement
      if (profiler != null) {
        try {
          await profiler.stopRecording(version: '1.0');
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Calcule les distances vectorielles et génère les résultats
  Future<List<RecommendationResult>> _computeVectorDistances({
    required UserVector userVector,
    required Map<String, DestinationVector> destVectors,
    required bool enableSerendipity,
    bool continentOnly = false,
    required int limit,
    PerformanceProfiler? profiler,
    String? stepPrefix,
  }) async {
    // Appliquer sérendipité si demandé
    final searchVector = enableSerendipity
        ? _vectorService.applySerendipity(
            userVector, 
            invertContinent: true,
            continentOnly: continentOnly,
          )
        : userVector;

    final results = <RecommendationResult>[];
    
    // Charger les destinations
    final allDestinations = await _destinationService.getAllDestinations();
    final destMap = {for (var d in allDestinations) d.id: d};

    // 🎯 ÉTAPE 1: Calcul des similarités cosinus (SANS bonus activités)
    if (profiler != null && stepPrefix != null) {
      await profiler.measureStep(
        '$stepPrefix - Calcul similarités',
        () async {
          for (final entry in destVectors.entries) {
            final destId = entry.key;
            final destVector = entry.value;
            final destination = destMap[destId];
            
            if (destination == null) continue;

            // Similarité cosinus
            final similarity = _vectorService.cosineSimilarity(
              searchVector.toArray(),
              destVector.toArray(),
            );

            // Score sur 100
            final score = (similarity + 1.0) * 50.0; // [-1,1] → [0,100]

            results.add(RecommendationResult(
              destination: destination,
              totalScore: score, // Score basé uniquement sur similarité
              scoreBreakdown: {
                'Similarité Vectorielle': score,
              },
              topActivities: [],
              isSerendipity: enableSerendipity,
            ));
          }
        },
      );
    } else {
      // Sans profiler (mode normal)
      for (final entry in destVectors.entries) {
        final destId = entry.key;
        final destVector = entry.value;
        final destination = destMap[destId];
        
        if (destination == null) continue;

        final similarity = _vectorService.cosineSimilarity(
          searchVector.toArray(),
          destVector.toArray(),
        );

        final score = (similarity + 1.0) * 50.0;

        results.add(RecommendationResult(
          destination: destination,
          totalScore: score,
          scoreBreakdown: {
            'Similarité Vectorielle': score,
          },
          topActivities: [],
          isSerendipity: enableSerendipity,
        ));
      }
    }

    // 🎯 ÉTAPE 2: Tri initial par similarité (avant bonus)
    if (profiler != null && stepPrefix != null) {
      await profiler.measureStep(
        '$stepPrefix - Tri',
        () async {
          results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        },
      );
    } else {
      results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    }

    // 🎯 ÉTAPE 3: Sélectionner les top destinations
    final topResults = results.take(limit).toList();
    
    // 🎯 ÉTAPE 4: Calculer bonus activités SEULEMENT pour les destinations retenues
    if (profiler != null && stepPrefix != null) {
      await profiler.measureStep(
        '$stepPrefix - Calcul bonus activités',
        () async {
          for (final result in topResults) {
            final activityBonus = await _calculateActivityBonus(result.destination, userVector);
            result.scoreBreakdown['Bonus Activités'] = activityBonus;
            // Mettre à jour le score total
            final similarity = result.scoreBreakdown['Similarité Vectorielle']!;
            result.totalScore = similarity + activityBonus;
          }
        },
      );
      
      // 🎯 ÉTAPE 5: Re-tri final avec les bonus (affine l'ordre des top destinations)
      await profiler.measureStep(
        '$stepPrefix - Tri final',
        () async {
          topResults.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        },
      );
    } else {
      // Sans profiler: calculer bonus et re-trier
      for (final result in topResults) {
        final activityBonus = await _calculateActivityBonus(result.destination, userVector);
        result.scoreBreakdown['Bonus Activités'] = activityBonus;
        final similarity = result.scoreBreakdown['Similarité Vectorielle']!;
        result.totalScore = similarity + activityBonus;
      }
      topResults.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    }

    return topResults;
  }

  /// Calcule un bonus basé sur les activités (score séparé)
  Future<double> _calculateActivityBonus(
    Destination dest,
    UserVector userVector,
  ) async {
    final activities = await _activityService.getActivitiesForDestination(dest.id);
    
    if (activities.isEmpty) return 0.0;

    // Compter les activités compatibles
    int matchCount = 0;
    for (final activity in activities) {
      final activityLevel = userVector.activity * 100; // 0-1 → 0-100
      final urbanLevel = userVector.urban * 100;
      
      if (ActivityService.matchesActivityLevel(activity, activityLevel) &&
          ActivityService.matchesUrbanLevel(activity, urbanLevel)) {
        matchCount++;
      }
    }

    // Bonus max: 5 points
    final matchRatio = matchCount / activities.length;
    return matchRatio * 5.0;
  }

  /// Enregistre une interaction récente (like/dislike)
  void recordInteraction(Destination destination, String action) {
    _biasService.addInteraction(destination, action);
  }

  /// Calcule les poids pour chaque continent basé sur le vecteur utilisateur
  /// Utilise DIRECTEMENT les composantes continent du vecteur (déjà entre 0 et 1)
  /// Retourne un Map<continent, poids> où la somme des poids vaut 1.0
  Map<String, double> _calculateContinentWeights(
    UserVector userVector,
    List<String> continents,
  ) {
    final mapping = {
      'Europe': 0,
      'Afrique': 1,
      'Asie': 2,
      'Amérique du Nord': 3,
      'Amérique du Sud': 4,
      'Océanie': 5,
    };
    
    final weights = <String, double>{};
    double totalWeight = 0.0;
    
    // Récupérer les poids depuis le vecteur utilisateur
    for (final continent in continents) {
      final index = mapping[continent];
      if (index != null && index < userVector.continentVector.length) {
        final weight = userVector.continentVector[index];
        weights[continent] = weight;
        totalWeight += weight;
      }
    }
    
    // Normaliser pour que la somme vaille 1
    if (totalWeight > 0) {
      weights.updateAll((key, value) => value / totalWeight);
    } else {
      // Si tous les poids sont nuls, répartir équitablement
      final equalWeight = 1.0 / continents.length;
      for (final continent in continents) {
        weights[continent] = equalWeight;
      }
    }
    
    return weights;
  }

  /// Équilibre les recommandations pour assurer une proportion de chaque continent sélectionné
  /// 
  /// [recommendations] Liste des recommandations à équilibrer
  /// [prefs] Préférences utilisateur (pour savoir quels continents)
  /// [targetCount] Nombre total de destinations à retourner
  /// 
  /// Retourne une liste équilibrée où chaque continent sélectionné est représenté proportionnellement
  List<RecommendationResult> balanceByContinent({
    required List<RecommendationResult> recommendations,
    required UserPreferencesV2 prefs,
    int targetCount = 10,
  }) {
    print('⚖️ === ÉQUILIBRAGE PAR CONTINENT ===');
    print('   ${recommendations.length} recommandations à équilibrer');
    print('   Continents sélectionnés: ${prefs.selectedContinents}');

    if (recommendations.isEmpty || prefs.selectedContinents.isEmpty) {
      return recommendations;
    }

    // Grouper par continent
    final byContinent = <String, List<RecommendationResult>>{};
    for (final continent in prefs.selectedContinents) {
      byContinent[continent] = [];
    }
    
    // Liste pour les recommandations d'autres continents
    final otherContinents = <RecommendationResult>[];

    // Répartir les recommandations
    for (final reco in recommendations) {
      bool assigned = false;
      for (final continent in prefs.selectedContinents) {
        if (DestinationService.matchesContinent(reco.destination, continent)) {
          byContinent[continent]!.add(reco);
          assigned = true;
          break;
        }
      }
      if (!assigned) {
        otherContinents.add(reco);
      }
    }

    // Afficher la répartition actuelle
    for (final entry in byContinent.entries) {
      print('   ${entry.key}: ${entry.value.length} destinations');
    }
    print('   Autres: ${otherContinents.length} destinations');

    // Trier chaque groupe par score (meilleurs en premier)
    for (final list in byContinent.values) {
      list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    }
    otherContinents.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // Calculer combien prendre de chaque continent (répartition équitable)
    final continentCount = prefs.selectedContinents.length;
    final perContinent = targetCount ~/ continentCount;
    final remainder = targetCount % continentCount;

    print('   📊 Objectif: $perContinent par continent (+ $remainder de bonus)');

    // === ÉTAPE CRITIQUE: Sélectionner le top 1 GLOBAL ===
    // Comparer les meilleures destinations de chaque continent pour trouver LA meilleure
    final topCandidates = <RecommendationResult>[];
    for (final continent in prefs.selectedContinents) {
      final list = byContinent[continent]!;
      if (list.isNotEmpty) {
        topCandidates.add(list.first);
      }
    }
    
    // Trier les top candidats pour trouver LE meilleur
    topCandidates.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    
    // Construire la liste équilibrée
    final balanced = <RecommendationResult>[];
    final addedIds = <String>{}; // Track IDs pour éviter les doublons
    
    // 1. Ajouter le top 1 global d'abord
    if (topCandidates.isNotEmpty) {
      final bestOverall = topCandidates.first;
      balanced.add(bestOverall);
      addedIds.add(bestOverall.destination.id);
      print('   🏆 TOP 1 GLOBAL: ${bestOverall.destination.city} (${bestOverall.totalScore.toStringAsFixed(1)} pts)');
    }
    
    // 2. Remplir le reste en alternant entre continents (round-robin)
    final iterators = <int, int>{};
    for (int i = 0; i < prefs.selectedContinents.length; i++) {
      iterators[i] = 0;
    }

    int attempts = 0;
    while (balanced.length < targetCount && attempts < targetCount * 2) {
      bool addedAny = false;
      
      for (int i = 0; i < prefs.selectedContinents.length; i++) {
        if (balanced.length >= targetCount) break;
        
        final continent = prefs.selectedContinents[i];
        final available = byContinent[continent]!;
        final index = iterators[i]!;
        
        if (index < available.length) {
          final candidate = available[index];
          // Vérifier qu'on n'a pas déjà cette destination
          if (!addedIds.contains(candidate.destination.id)) {
            balanced.add(candidate);
            addedIds.add(candidate.destination.id);
            addedAny = true;
          }
          iterators[i] = index + 1;
        }
      }
      
      if (!addedAny) break; // Plus rien à ajouter
      attempts++;
    }

    // Si on n'a pas assez, compléter avec les meilleures restantes (tous continents)
    if (balanced.length < targetCount) {
      final remaining = recommendations
          .where((r) => !addedIds.contains(r.destination.id))
          .take(targetCount - balanced.length);
      balanced.addAll(remaining);
      for (final r in remaining) {
        addedIds.add(r.destination.id);
      }
      print('   ➕ ${remaining.length} destinations supplémentaires pour compléter');
    }

    // Mélanger légèrement pour éviter un pattern trop rigide
    // Mais garder les meilleurs en début
    if (balanced.length > 3) {
      final top3 = balanced.take(3).toList();
      final rest = balanced.skip(3).toList();
      rest.shuffle(Random());
      balanced.clear();
      balanced.addAll(top3);
      balanced.addAll(rest);
    }

    print('   ✅ ${balanced.length} destinations équilibrées');
    return balanced.take(targetCount).toList();
  }
}

