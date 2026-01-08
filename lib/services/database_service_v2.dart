import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/destination_v2.dart';
import '../models/activity_v2.dart';

/// Service de base de données V2 - Utilise directement bd.db depuis assets
/// Plus besoin de charger depuis CSV, la base est prête à l'emploi
class DatabaseServiceV2 {
  static final DatabaseServiceV2 _instance = DatabaseServiceV2._internal();
  static Database? _database;

  factory DatabaseServiceV2() => _instance;
  DatabaseServiceV2._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'serenola_v2.db');
    
    print('📂 Chemin BDD V2: $path');

    // Toujours copier la base depuis assets pour être sûr d'avoir la dernière version
    try {
      // Supprimer l'ancienne si elle existe
      if (await databaseExists(path)) {
        await deleteDatabase(path);
        print('🗑️ Ancienne base supprimée');
      }

      // Copier depuis assets/database/bd.db
      print('📦 Copie de bd.db depuis assets/database...');
      final ByteData data = await rootBundle.load('assets/database/bd.db');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Écrire dans le répertoire de l'app
      await Directory(dirname(path)).create(recursive: true);
      await File(path).writeAsBytes(bytes, flush: true);
      
      print('✅ Base de données copiée avec succès');
    } catch (e, stackTrace) {
      print('❌ Erreur copie BD: $e');
      print(stackTrace);
      throw Exception('Impossible de copier la base de données: $e');
    }

    // Ouvrir la base
    return await openDatabase(
      path,
      readOnly: false,
      singleInstance: true,
    );
  }

  /// Récupère toutes les destinations
  Future<List<DestinationV2>> getAllDestinations() async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query('destination');
      print('📊 ${maps.length} destinations trouvées en DB');
      
      return maps.map((row) => DestinationV2.fromDb(row)).toList();
    } catch (e) {
      print('❌ Erreur lecture destinations: $e');
      return [];
    }
  }

  /// Récupère une destination par ID
  Future<DestinationV2?> getDestinationById(String id) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'destinations',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      return DestinationV2.fromDb(maps.first);
    } catch (e) {
      print('❌ Erreur lecture destination $id: $e');
      return null;
    }
  }

  /// Récupère les destinations par continent/région
  Future<List<DestinationV2>> getDestinationsByRegion(String region) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'destination',
        where: 'region = ?',
        whereArgs: [region.toLowerCase()],
      );
      
      return maps.map((row) => DestinationV2.fromDb(row)).toList();
    } catch (e) {
      print('❌ Erreur lecture destinations région $region: $e');
      return [];
    }
  }

  /// Récupère les activités pour une destination
  Future<List<ActivityV2>> getActivitiesForDestination(String destinationId) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'activite',
        where: 'id_destination = ?',
        whereArgs: [destinationId],
      );
      
      return maps.map((row) => ActivityV2.fromDb(row)).toList();
    } catch (e) {
      print('❌ Erreur lecture activités pour $destinationId: $e');
      return [];
    }
  }

  /// Compte le nombre de destinations
  Future<int> getDestinationsCount() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM destination');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Erreur comptage destinations: $e');
      return 0;
    }
  }

  /// Compte le nombre d'activités
  Future<int> getActivitiesCount() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM activite');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Erreur comptage activités: $e');
      return 0;
    }
  }

  /// Recherche de destinations par texte (ville, pays, tags)
  Future<List<DestinationV2>> searchDestinations(String query) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM destination 
        WHERE city LIKE ? OR country LIKE ? OR tags LIKE ?
        LIMIT 20
      ''', ['%$query%', '%$query%', '%$query%']);
      
      return maps.map((row) => DestinationV2.fromDb(row)).toList();
    } catch (e) {
      print('❌ Erreur recherche "$query": $e');
      return [];
    }
  }

  /// Ferme la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🔒 Base de données fermée');
  }

  /// Réinitialise la base (pour tests ou mises à jour)
  Future<void> reset() async {
    await close();
    _database = await _initializeDatabase();
    print('🔄 Base de données réinitialisée');
  }

  /// Affiche des statistiques sur la DB
  Future<Map<String, dynamic>> getStats() async {
    final destCount = await getDestinationsCount();
    final actCount = await getActivitiesCount();
    
    final destinations = await getAllDestinations();
    final regions = <String, int>{};
    final budgets = <String, int>{};
    
    for (final dest in destinations) {
      regions[dest.region] = (regions[dest.region] ?? 0) + 1;
      budgets[dest.budgetLevel] = (budgets[dest.budgetLevel] ?? 0) + 1;
    }
    
    return {
      'destinations': destCount,
      'activities': actCount,
      'regions': regions,
      'budgets': budgets,
    };
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
