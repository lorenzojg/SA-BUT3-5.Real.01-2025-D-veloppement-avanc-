import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/destination_model.dart';
import '../models/user_interaction_model.dart';
import '../models/activity_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'serenola.db');
    print('📂 Chemin BDD: $path');

    // ✅ Vérifier si la base existe déjà
    final exists = await databaseExists(path);

    if (!exists) {
      print('📦 Copie de la base de données depuis les assets...');
      try {
        // Créer le dossier parent si nécessaire
        await Directory(dirname(path)).create(recursive: true);

        // Copier depuis les assets
        ByteData data = await rootBundle.load('assets/database/serenola.db');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        
        // Écrire le fichier
        await File(path).writeAsBytes(bytes, flush: true);
        print('✅ Base de données copiée avec succès');
      } catch (e) {
        print('❌ Erreur lors de la copie de la base de données: $e');
        // Fallback: Laisser openDatabase créer une base vide
      }
    } else {
      print('✅ La base de données existe déjà');
    }

    return await openDatabase(
      path,
      version: 7,
      // onCreate n'est appelé que si la base est créée par openDatabase (donc vide)
      // Si on a copié le fichier, onCreate ne sera PAS appelé, ce qui est ce qu'on veut.
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Si nous montons de version (par exemple 2 -> 3)
    if (oldVersion < newVersion) {
      // Stratégie simple : Supprimer et recréer la table destinations. 
      // Ceci est justifié ici car nous savons que la structure a changé.
      await db.execute('DROP TABLE IF EXISTS destinations');
      // Pour la version 7, on recrée aussi la table activities si elle existait (peu probable)
      await db.execute('DROP TABLE IF EXISTS activities');
      await _createTables(db, newVersion);
      print('🔄 Base de données mise à jour vers la version $newVersion');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS destinations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        continent TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        activities TEXT NOT NULL,
        averageCost REAL NOT NULL,
        climate TEXT NOT NULL,
        duration INTEGER NOT NULL,
        description TEXT NOT NULL,
        travelTypes TEXT NOT NULL,
        rating REAL NOT NULL,
        annualVisitors REAL NOT NULL,
        unescoSite INTEGER NOT NULL,
        activityScore REAL NOT NULL,
        scoreCulture REAL DEFAULT 0.0,
        scoreAdventure REAL DEFAULT 0.0,
        scoreNature REAL DEFAULT 0.0,
        scoreBeaches REAL DEFAULT 0.0,
        scoreNightlife REAL DEFAULT 0.0,
        scoreCuisine REAL DEFAULT 0.0,
        scoreWellness REAL DEFAULT 0.0,
        scoreUrban REAL DEFAULT 0.0,
        scoreSeclusion REAL DEFAULT 0.0,
        monthlyFlightPrices TEXT
      )
    ''');
    
    // ✅ Création de la table interactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destinationId TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        durationMs INTEGER NOT NULL
      )
    ''');

    // ✅ Création de la table activities (Version 7)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        country TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        categories TEXT NOT NULL,
        rating REAL NOT NULL,
        hasFee INTEGER NOT NULL,
        hasWheelchair INTEGER NOT NULL
      )
    ''');
    
    print('✅ Tables créées (version $version)');
  }

  // ✅ Ajouter une destination
  Future<void> insertDestination(Destination destination) async {
    final db = await database;
    await db.insert(
      'destinations',
      {
        'id': destination.id,
        'name': destination.name,
        'country': destination.country,
        'continent': destination.continent,
        'latitude': destination.latitude,
        'longitude': destination.longitude,
        'activities': destination.activities.join(','),
        'averageCost': destination.averageCost,
        'climate': destination.climate,
        'duration': destination.duration,
        'description': destination.description,
        'travelTypes': destination.travelTypes.join(','),
        'rating': destination.rating,
        'annualVisitors': destination.annualVisitors,
        'unescoSite': destination.unescoSite ? 1 : 0,
        'activityScore': destination.activityScore,
        'scoreCulture': destination.scoreCulture,
        'scoreAdventure': destination.scoreAdventure,
        'scoreNature': destination.scoreNature,
        'scoreBeaches': destination.scoreBeaches,
        'scoreNightlife': destination.scoreNightlife,
        'scoreCuisine': destination.scoreCuisine,
        'scoreWellness': destination.scoreWellness,
        'scoreUrban': destination.scoreUrban,
        'scoreSeclusion': destination.scoreSeclusion,
        'monthlyFlightPrices': destination.monthlyFlightPrices != null ? jsonEncode(destination.monthlyFlightPrices) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ✅ Récupérer toutes les destinations
  Future<List<Destination>> getAllDestinations() async {
    final db = await database;
    final maps = await db.query('destinations');

    return List.generate(maps.length, (i) {
      final map = maps[i];
      // Sécurisation: Utiliser ?? 50.0 au cas où la colonne n'est pas encore créée
      // ou contient une valeur nulle (ce qui ne devrait pas arriver avec la migration)
      final activityScore = (map['activityScore'] as num? ?? 50).toInt();

      return Destination(
        id: map['id'] as String,
        name: map['name'] as String,
        country: map['country'] as String,
        continent: map['continent'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        activities: (map['activities'] as String).split(','),
        averageCost: (map['averageCost'] as num).toDouble(),
        climate: map['climate'] as String,
        duration: (map['duration'] as num).toInt(),
        description: map['description'] as String,
        travelTypes: (map['travelTypes'] as String).split(','),
        rating: (map['rating'] as num).toDouble(),
        annualVisitors: (map['annualVisitors'] as num).toDouble(),
        unescoSite: (map['unescoSite'] as int) == 1,
        activityScore: activityScore, // ✅ Lecture sécurisée
        scoreCulture: (map['scoreCulture'] as num? ?? 0.0).toDouble(),
        scoreAdventure: (map['scoreAdventure'] as num? ?? 0.0).toDouble(),
        scoreNature: (map['scoreNature'] as num? ?? 0.0).toDouble(),
        scoreBeaches: (map['scoreBeaches'] as num? ?? 0.0).toDouble(),
        scoreNightlife: (map['scoreNightlife'] as num? ?? 0.0).toDouble(),
        scoreCuisine: (map['scoreCuisine'] as num? ?? 0.0).toDouble(),
        scoreWellness: (map['scoreWellness'] as num? ?? 0.0).toDouble(),
        scoreUrban: (map['scoreUrban'] as num? ?? 0.0).toDouble(),
        scoreSeclusion: (map['scoreSeclusion'] as num? ?? 0.0).toDouble(),
        monthlyFlightPrices: map['monthlyFlightPrices'] != null 
            ? List<int>.from(jsonDecode(map['monthlyFlightPrices'] as String)) 
            : null,
      );
    });
  }

  // ✅ Récupérer une destination par ID
  Future<Destination?> getDestinationById(String id) async {
    final db = await database;
    final maps = await db.query(
      'destinations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    
    // Sécurisation de la lecture de activityScore
    final activityScore = (map['activityScore'] as num? ?? 50).toInt();

    return Destination(
      id: map['id'] as String,
      name: map['name'] as String,
      country: map['country'] as String,
      continent: map['continent'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      activities: (map['activities'] as String).split(','),
      averageCost: (map['averageCost'] as num).toDouble(),
      climate: map['climate'] as String,
      duration: (map['duration'] as num).toInt(),
      description: map['description'] as String,
      travelTypes: (map['travelTypes'] as String).split(','),
      rating: (map['rating'] as num).toDouble(),
      annualVisitors: (map['annualVisitors'] as num).toDouble(),
      unescoSite: (map['unescoSite'] as int) == 1,
      activityScore: activityScore, // ✅ Lecture sécurisée
      scoreCulture: (map['scoreCulture'] as num? ?? 0.0).toDouble(),
      scoreAdventure: (map['scoreAdventure'] as num? ?? 0.0).toDouble(),
      scoreNature: (map['scoreNature'] as num? ?? 0.0).toDouble(),
      scoreBeaches: (map['scoreBeaches'] as num? ?? 0.0).toDouble(),
      scoreNightlife: (map['scoreNightlife'] as num? ?? 0.0).toDouble(),
      scoreCuisine: (map['scoreCuisine'] as num? ?? 0.0).toDouble(),
      scoreWellness: (map['scoreWellness'] as num? ?? 0.0).toDouble(),
      scoreUrban: (map['scoreUrban'] as num? ?? 0.0).toDouble(),
      scoreSeclusion: (map['scoreSeclusion'] as num? ?? 0.0).toDouble(),
      monthlyFlightPrices: map['monthlyFlightPrices'] != null 
          ? List<int>.from(jsonDecode(map['monthlyFlightPrices'] as String)) 
          : null,
    );
  }

  // ✅ Filtrer les destinations par continent
  Future<List<Destination>> getDestinationsByContinent(String continent) async {
    final db = await database;
    final maps = await db.query(
      'destinations',
      where: 'continent = ?',
      whereArgs: [continent],
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final activityScore = (map['activityScore'] as num? ?? 50).toInt();

      return Destination(
        id: map['id'] as String,
        name: map['name'] as String,
        country: map['country'] as String,
        continent: map['continent'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        activities: (map['activities'] as String).split(','),
        averageCost: (map['averageCost'] as num).toDouble(),
        climate: map['climate'] as String,
        duration: (map['duration'] as num).toInt(),
        description: map['description'] as String,
        travelTypes: (map['travelTypes'] as String).split(','),
        rating: (map['rating'] as num).toDouble(),
        annualVisitors: (map['annualVisitors'] as num).toDouble(),
        unescoSite: (map['unescoSite'] as int) == 1,
        activityScore: activityScore, // ✅ Lecture sécurisée
        scoreCulture: (map['scoreCulture'] as num? ?? 0.0).toDouble(),
        scoreAdventure: (map['scoreAdventure'] as num? ?? 0.0).toDouble(),
        scoreNature: (map['scoreNature'] as num? ?? 0.0).toDouble(),
        scoreBeaches: (map['scoreBeaches'] as num? ?? 0.0).toDouble(),
        scoreNightlife: (map['scoreNightlife'] as num? ?? 0.0).toDouble(),
        scoreCuisine: (map['scoreCuisine'] as num? ?? 0.0).toDouble(),
        scoreWellness: (map['scoreWellness'] as num? ?? 0.0).toDouble(),
        scoreUrban: (map['scoreUrban'] as num? ?? 0.0).toDouble(),
        scoreSeclusion: (map['scoreSeclusion'] as num? ?? 0.0).toDouble(),
        monthlyFlightPrices: map['monthlyFlightPrices'] != null 
            ? List<int>.from(jsonDecode(map['monthlyFlightPrices'] as String)) 
            : null,
      );
    });
  }

  // ✅ Enregistrer une interaction utilisateur
  Future<void> recordInteraction(UserInteraction interaction) async {
    final db = await database;
    await db.insert(
      'interactions',
      interaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // print('💾 Interaction enregistrée: ${interaction.type} sur ${interaction.destinationId}');
  }

  // ✅ Récupérer toutes les interactions
  Future<List<UserInteraction>> getAllInteractions() async {
    final db = await database;
    final maps = await db.query('interactions', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) {
      return UserInteraction.fromJson(maps[i]);
    });
  }

  // ✅ Vider la table (utile pour les tests)
  Future<void> clearDestinations() async {
    final db = await database;
    await db.delete('destinations');
    print('🗑️ Table destinations vidée');
  }

  // ✅ Compter le nombre de destinations
  Future<int> getDestinationsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM destinations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ✅ Ajouter une activité
  Future<void> insertActivity(Activity activity) async {
    final db = await database;
    await db.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ✅ Récupérer les activités pour une destination (ville)
  Future<List<Activity>> getActivitiesForDestination(String city) async {
    final db = await database;
    final maps = await db.query(
      'activities',
      where: 'city = ?',
      whereArgs: [city],
    );

    return List.generate(maps.length, (i) {
      return Activity.fromMap(maps[i]);
    });
  }

  // ✅ Vider la table activities
  Future<void> clearActivities() async {
    final db = await database;
    await db.delete('activities');
    print('🗑️ Table activities vidée');
  }
}