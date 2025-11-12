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
      version: 2,  // ✅ Version 2 pour forcer la migration
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Supprimer l'ancienne table et recréer avec les nouveaux champs
      await db.execute('DROP TABLE IF EXISTS destinations');
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
        unescoSite INTEGER NOT NULL
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
        'continent': destination.continent,  // ✅ Ajouté
        'latitude': destination.latitude,
        'longitude': destination.longitude,
        'activities': destination.activities.join(','),
        'averageCost': destination.averageCost,
        'climate': destination.climate,
        'duration': destination.duration,
        'description': destination.description,
        'travelTypes': destination.travelTypes.join(','),  // ✅ Ajouté
        'rating': destination.rating,  // ✅ Ajouté
        'annualVisitors': destination.annualVisitors,  // ✅ Ajouté
        'unescoSite': destination.unescoSite ? 1 : 0,  // ✅ Ajouté (SQLite utilise 0/1 pour les booléens)
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ✅ Récupérer toutes les destinations
  Future<List<Destination>> getAllDestinations() async {
    final db = await database;
    final maps = await db.query('destinations');

    return List.generate(maps.length, (i) {
      return Destination(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        country: maps[i]['country'] as String,
        continent: maps[i]['continent'] as String,  // ✅ Ajouté
        latitude: maps[i]['latitude'] as double,
        longitude: maps[i]['longitude'] as double,
        activities: (maps[i]['activities'] as String).split(','),
        averageCost: maps[i]['averageCost'] as double,
        climate: maps[i]['climate'] as String,
        duration: maps[i]['duration'] as int,
        description: maps[i]['description'] as String,
        travelTypes: (maps[i]['travelTypes'] as String).split(','),  // ✅ Ajouté
        rating: maps[i]['rating'] as double,  // ✅ Ajouté
        annualVisitors: maps[i]['annualVisitors'] as double,  // ✅ Ajouté
        unescoSite: (maps[i]['unescoSite'] as int) == 1,  // ✅ Ajouté (convertir 0/1 en bool)
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
    return Destination(
      id: map['id'] as String,
      name: map['name'] as String,
      country: map['country'] as String,
      continent: map['continent'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      activities: (map['activities'] as String).split(','),
      averageCost: map['averageCost'] as double,
      climate: map['climate'] as String,
      duration: map['duration'] as int,
      description: map['description'] as String,
      travelTypes: (map['travelTypes'] as String).split(','),
      rating: map['rating'] as double,
      annualVisitors: map['annualVisitors'] as double,
      unescoSite: (map['unescoSite'] as int) == 1,
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
      return Destination(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        country: maps[i]['country'] as String,
        continent: maps[i]['continent'] as String,
        latitude: maps[i]['latitude'] as double,
        longitude: maps[i]['longitude'] as double,
        activities: (maps[i]['activities'] as String).split(','),
        averageCost: maps[i]['averageCost'] as double,
        climate: maps[i]['climate'] as String,
        duration: maps[i]['duration'] as int,
        description: maps[i]['description'] as String,
        travelTypes: (maps[i]['travelTypes'] as String).split(','),
        rating: maps[i]['rating'] as double,
        annualVisitors: maps[i]['annualVisitors'] as double,
        unescoSite: (maps[i]['unescoSite'] as int) == 1,
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
