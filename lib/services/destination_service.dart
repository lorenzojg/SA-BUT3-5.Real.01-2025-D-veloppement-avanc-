import '../data/app_database.dart';

import '../models/destination_model.dart';

/// Service pour gérer la logique métier liée aux destinations
/// Sépare du modèle de données
class DestinationService {
  /// Obtient la température moyenne pour un mois donné (1-12)
  static double? getAvgTemp(Destination destination, int month) {
    return destination.avgTempMonthly[month]?['avg'];
  }

  /// Obtient la température min pour un mois donné
  static double? getMinTemp(Destination destination, int month) {
    return destination.avgTempMonthly[month]?['min'];
  }

  /// Obtient la température max pour un mois donné
  static double? getMaxTemp(Destination destination, int month) {
    return destination.avgTempMonthly[month]?['max'];
  }

  /// Obtient le prix du vol pour un mois donné (1-12)
  static int? getFlightPrice(Destination destination, int month) {
    if (destination.prixVolParMois == null || month < 1 || month > 12) return null;
    return destination.prixVolParMois![month - 1];
  }

  /// Convertit le budget_level en valeur numérique (0-4)
  static double getBudgetLevelNumeric(Destination destination) {
    switch (destination.budgetLevel) {
      case 'Budget':
        return 0.0;
      case 'Mid-range':
        return 2.0;
      case 'Luxury':
        return 4.0;
      default:
        return 2.0;
    }
  }

  /// Calcule un score d'activité basé sur les scores vectoriels (0-100)
  /// Plus le score est élevé, plus la destination est sportive/aventure
  static double calculateActivityScore(Destination destination) {
    // Pondération: adventure et nature = sportif, wellness et seclusion = détente
    double sportifScore = (destination.scoreAdventure * 2.0 + destination.scoreNature) / 3.0;
    double detenteScore = (destination.scoreWellness * 2.0 + destination.scoreSeclusion + destination.scoreBeaches) / 4.0;
    
    // Normaliser sur 0-100 (scores DB sont sur 0-5)
    return ((sportifScore - detenteScore + 5) / 10 * 100).clamp(0, 100);
  }

  /// Calcule un score d'urbanité (0-100)
  /// Plus le score est élevé, plus la destination est urbaine
  static double calculateUrbanScore(Destination destination) {
    // Pondération: urban et nightlife = ville, nature et seclusion = nature
    double villeScore = (destination.scoreUrban * 2.0 + destination.scoreNightlife) / 3.0;
    double natureScore = (destination.scoreNature * 2.0 + destination.scoreSeclusion) / 3.0;
    
    // Normaliser sur 0-100
    return ((villeScore - natureScore + 5) / 10 * 100).clamp(0, 100);
  }

  /// Convertit une destination en chaîne de caractères
  static String destinationToString(Destination destination) {
    return '📍 ${destination.city}, ${destination.country} (${destination.region}) - Budget: ${destination.budgetLevel}';
  }

  /// Vérifie si la destination correspond au continent demandé
  static bool matchesContinent(Destination destination, String continent) {
    return destination.region == continent;
  }

  /// Récupère une destination par ID
  Future<Destination?> getDestinationById(String id) async {
    final db = await AppDatabase().database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'Destination',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      return Destination.fromMap(maps.first);
    } catch (e) {
      print('❌ Erreur lecture destination $id: $e');
      return null;
    }
  }

  // Compte le nombre de destinations
  Future<int> getDestinationsCount() async {
    final db = await AppDatabase().database;
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM Destination');
      final count = result.first['count'] as int?;
      return count ?? 0;
    } catch (e) {
      print('❌ Erreur comptage destinations: $e');
      return 0;
    }
  }

  /// Recherche de destinations par texte (ville, pays, tags)
  Future<List<Destination>> searchDestinations(String query) async {
    final db = await AppDatabase().database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM Destination 
        WHERE ville LIKE ? OR pays LIKE ? OR tags LIKE ?
        LIMIT 20
      ''', ['%$query%', '%$query%', '%$query%']);
      
      return maps.map((row) => Destination.fromMap(row)).toList();
    } catch (e) {
      print('❌ Erreur recherche "$query": $e');
      return [];
    }
  }

  /// Récupère toutes les destinations
  Future<List<Destination>> getAllDestinations() async {
    final db = await AppDatabase().database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query('Destination');
      print('📊 ${maps.length} destinations trouvées en DB');
      
      return maps.map((row) => Destination.fromMap(row)).toList();
    } catch (e) {
      print('❌ Erreur lecture destinations: $e');
      return [];
    }
  }

  

  /// Récupère les destinations par continent/région
  Future<List<Destination>> getDestinationsByRegion(String region) async {
    final db = await AppDatabase().database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'Destination',
        where: 'region = ?',
        whereArgs: [region.toLowerCase()],
      );
      
      return maps.map((row) => Destination.fromMap(row)).toList();
    } catch (e) {
      print('❌ Erreur lecture destinations région $region: $e');
      return [];
    }
  }

  /// Récupère les températures min et max parmi toutes les destinations
  Future<Map<String, double>> getTemperatureRange() async {
    final destinations = await getAllDestinations();
    
    if (destinations.isEmpty) {
      return {'min': -10.0, 'max': 40.0}; // Valeurs par défaut
    }
    
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;
    
    for (final dest in destinations) {
      if (dest.avgTempMonthly.isNotEmpty) {
        // Parcourir les températures mensuelles (Map<int, Map<String, double>>)
        for (final monthData in dest.avgTempMonthly.values) {
          final avgTemp = monthData['avg'];
          if (avgTemp != null) {
            if (avgTemp < minTemp) minTemp = avgTemp;
            if (avgTemp > maxTemp) maxTemp = avgTemp;
          }
        }
      }
    }
    
    // Si aucune température trouvée, utiliser valeurs par défaut
    if (minTemp == double.infinity || maxTemp == double.negativeInfinity) {
      return {'min': -10.0, 'max': 40.0};
    }
    
    return {
      'min': minTemp.floorToDouble(),
      'max': maxTemp.ceilToDouble(),
    };
  }
}