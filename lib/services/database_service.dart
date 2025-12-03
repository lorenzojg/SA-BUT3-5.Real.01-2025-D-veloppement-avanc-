import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/destination_model.dart';

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

    return await openDatabase(
      path,
      version: 3,  // ✅ Version incrémentée à 3 pour forcer la recréation
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Si nous montons de version (par exemple 2 -> 3)
    if (oldVersion < newVersion) {
      // Stratégie simple : Supprimer et recréer la table. 
      // Ceci est justifié ici car nous savons que la structure a changé.
      await db.execute('DROP TABLE IF EXISTS destinations');
      await _createTables(db, newVersion);
      print('🔄 Base de données mise à jour vers la version $newVersion');
    }
    // Si la nouvelle version est la 3, nous recréons la table complète.
    if (newVersion == 3) {
      await db.execute('DROP TABLE IF EXISTS destinations');
      await _createTables(db, newVersion);
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
        activityScore REAL NOT NULL 
      )
    ''');
    print('✅ Table destinations créée (version $version)');
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
        'activityScore': destination.activityScore, // ✅ Doit être présent
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
      );
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
}