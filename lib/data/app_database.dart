// Le rôle de ce fichier est de copier la base de données sqlite vers le dossier système de l'application

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() => _instance;
  AppDatabase._internal();

  /// Accès public à la base
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialisation complète
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bd.db');

    // Copier la DB depuis assets si elle n'existe pas encore
    final exists = await databaseExists(path);

    if (!exists) {
      await _copyDatabaseFromAssets(path);
    }

    return openDatabase(
      path,
      readOnly: true,
    );
  }

  /// Copie depuis assets → stockage système
  Future<void> _copyDatabaseFromAssets(String path) async {
    try {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/database/bd.db');
      final bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw Exception('Erreur lors de la copie de la base : $e');
    }
  }
}