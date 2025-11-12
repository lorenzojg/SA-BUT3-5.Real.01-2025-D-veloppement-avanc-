import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/destination_model.dart';
import 'database_service.dart';

class DataLoaderService {
  static final DataLoaderService _instance = DataLoaderService._internal();

  factory DataLoaderService() {
    return _instance;
  }

  DataLoaderService._internal();

  // ✅ Charger les données JSON et les insérer en base
  Future<void> loadInitialData() async {
    final db = DatabaseService();

    // Vérifie si les données sont déjà chargées
    final existingDestinations = await db.getAllDestinations();
    if (existingDestinations.isNotEmpty) {
      print('✅ ${existingDestinations.length} destinations déjà en base');
      return;
    }

    print('📦 Chargement des destinations depuis le JSON...');
    final destinations = await _loadDestinationsFromAssets();

    for (final destination in destinations) {
      await db.insertDestination(destination);
      print('  ✓ ${destination.name} ajoutée');
    }

    print('✅ ${destinations.length} destinations chargées en base');
  }

  // ✅ Charger le fichier JSON depuis les assets
  Future<List<Destination>> _loadDestinationsFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/destinations.json');
      final jsonData = jsonDecode(jsonString);
      final destinationList = jsonData['destinations'] as List;

      return destinationList
          .map((json) => Destination.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Erreur de chargement du JSON: $e');
      return [];
    }
  }
}
