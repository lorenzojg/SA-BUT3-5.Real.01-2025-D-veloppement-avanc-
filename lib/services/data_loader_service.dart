import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/destination_model.dart';
import 'database_service.dart';
import 'activity_analyzer_service.dart';

class DataLoaderService {
  static final DataLoaderService _instance = DataLoaderService._internal();

  factory DataLoaderService() {
    return _instance;
  }

  DataLoaderService._internal();

  // ✅ Charger les données CSV et les insérer en base
  Future<void> loadInitialData() async {
    final db = DatabaseService();

    // Vérifie si les données sont déjà chargées
    final existingDestinations = await db.getAllDestinations();
    if (existingDestinations.isNotEmpty) {
      print('✅ ${existingDestinations.length} destinations déjà en base');
      return;
    }

    print('📦 Chargement des destinations depuis les CSV...');
    final destinations = await _loadDestinationsFromCsv();

    for (final destination in destinations) {
      await db.insertDestination(destination);
      // print('  ✓ ${destination.name} ajoutée');
    }

    print('✅ ${destinations.length} destinations chargées en base');

    // Charger aussi les données d'activités pour l'analyseur
    print('📦 Chargement des données d\'activités et de prix...');
    await ActivityAnalyzerService().loadActivities();
    await ActivityAnalyzerService().loadPrices();
    print('✅ Données d\'activités et de prix chargées');
  }

  Future<List<Destination>> _loadDestinationsFromCsv() async {
    try {
      // 1. Load Worldwide Dataset (Base)
      final String worldwideData = await rootBundle.loadString(
        'assets/data/Worldwide_Travel_Cities_Dataset_Ratings_and_Climate.csv',
      );
      List<List<dynamic>> worldwideRows = const CsvToListConverter().convert(
        worldwideData,
        eol: '\n',
      );

      // 2. Load City Data (Enrichment)
      final String cityData = await rootBundle.loadString(
        'assets/data/city_data.csv',
      );
      List<List<dynamic>> cityRows = const CsvToListConverter().convert(
        cityData,
        eol: '\n',
      );

      // Map city_data by City Name
      Map<String, Map<String, dynamic>> cityDataMap = {};
      for (var i = 1; i < cityRows.length; i++) {
        var row = cityRows[i];
        if (row.isEmpty) continue;
        String city = row[0].toString().trim();
        cityDataMap[city] = {
          'climat_details': row.length > 3 ? row[3] : '',
          'hebergement_moyen': row.length > 4 ? row[4] : 0,
          'tags': row.length > 7 ? row[7] : '',
        };
      }

      // 3. Load Prix Moyens (Enrichment)
      final String prixData = await rootBundle.loadString(
        'assets/data/prixMoyens.csv',
      );
      List<List<dynamic>> prixRows = const CsvToListConverter().convert(
        prixData,
        eol: '\n',
      );

      Map<String, double> countryCostMap = {};
      for (var i = 1; i < prixRows.length; i++) {
        var row = prixRows[i];
        if (row.isEmpty) continue;
        if (row.length > 3) {
          String country = row[1].toString().trim();
          double cost = double.tryParse(row[3].toString()) ?? 0.0;
          countryCostMap[country.toLowerCase()] = cost;
        }
      }

      Map<String, String> countryEnToFr = {
        'Italy': 'Italie',
        'Fiji': 'Iles Fidji',
        'Canada': 'Canada',
        'Mexico': 'Mexique',
        'Indonesia': 'Indonésie',
        'Greenland': 'Groenland',
        'Namibia': 'Namibie',
        'Jamaica': 'Jamaïque',
        'Greece': 'Grèce',
        'Georgia': 'Géorgie',
        'Germany': 'Allemagne',
        'Australia': 'Australie',
        'Japan': 'Japon',
        'Netherlands': 'Pays-Bas',
        'Myanmar': 'Birmanie',
        'Sweden': 'Suède',
        'United States': 'Etats-Unis',
        'France': 'France',
        'Spain': 'Espagne',
        'United Kingdom': 'Royaume Uni',
        'Thailand': 'Thaïlande',
        'Vietnam': 'Vietnam',
        'India': 'Inde',
        'China': 'Chine',
        'Brazil': 'Brésil',
        'Argentina': 'Argentine',
        'Peru': 'Pérou',
        'South Africa': 'Afrique du Sud',
        'Egypt': 'Egypte',
        'Morocco': 'Maroc',
        'Turkey': 'Turquie',
        'Russia': 'Russie',
        'Portugal': 'Portugal',
        'Switzerland': 'Suisse',
        'Austria': 'Autriche',
        'Belgium': 'Belgique',
        'Ireland': 'Irlande',
        'Norway': 'Norvège',
        'Denmark': 'Danemark',
        'Finland': 'Finlande',
        'Iceland': 'Islande',
        'New Zealand': 'Nouvelle Zélande',
      };

      List<Destination> destinations = [];

      for (var i = 1; i < worldwideRows.length; i++) {
        var row = worldwideRows[i];
        if (row.length < 19) continue;

        String id = row[0].toString();
        String name = row[1].toString();
        String country = row[2].toString();
        String continent = row[3].toString();
        String description = row[4].toString();
        double latitude = double.tryParse(row[5].toString()) ?? 0.0;
        double longitude = double.tryParse(row[6].toString()) ?? 0.0;

        String idealDurationsRaw = row[8].toString();
        int duration = 7;
        if (idealDurationsRaw.contains('Weekend')) duration = 3;
        if (idealDurationsRaw.contains('One week')) duration = 7;
        if (idealDurationsRaw.contains('Long trip')) duration = 14;

        String budgetLevel = row[9].toString();

        double scoreCulture = (double.tryParse(row[10].toString()) ?? 0.0);
        double scoreAdventure = (double.tryParse(row[11].toString()) ?? 0.0);
        double scoreNature = (double.tryParse(row[12].toString()) ?? 0.0);
        double scoreBeaches = (double.tryParse(row[13].toString()) ?? 0.0);
        double scoreNightlife = (double.tryParse(row[14].toString()) ?? 0.0);
        double scoreCuisine = (double.tryParse(row[15].toString()) ?? 0.0);
        double scoreWellness = (double.tryParse(row[16].toString()) ?? 0.0);
        double scoreUrban = (double.tryParse(row[17].toString()) ?? 0.0);
        double scoreSeclusion = (double.tryParse(row[18].toString()) ?? 0.0);

        var cityExtra = cityDataMap[name];
        String climate = "Moderate";
        List<String> activities = [];
        double cityCost = 0.0;

        if (cityExtra != null) {
          climate = cityExtra['climat_details'].toString();
          if (climate.length > 100) climate = "${climate.substring(0, 100)}...";

          String tagsRaw = cityExtra['tags'].toString();
          tagsRaw = tagsRaw
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '');
          if (tagsRaw.isNotEmpty) {
            activities = tagsRaw.split(',').map((e) => e.trim()).toList();
          }
          cityCost =
              double.tryParse(cityExtra['hebergement_moyen'].toString()) ?? 0.0;
        }

        double countryCost = 0.0;
        String countryFr = countryEnToFr[country] ?? country;
        countryCost = countryCostMap[countryFr.toLowerCase()] ?? 0.0;

        double averageCost = 0.0;
        if (cityCost > 0) {
          averageCost = cityCost;
        } else if (countryCost > 0) {
          averageCost = countryCost / 7;
        } else {
          if (budgetLevel == 'Luxury') {
            averageCost = 300.0;
          } else if (budgetLevel == 'Mid-range')
            averageCost = 150.0;
          else
            averageCost = 80.0;
        }

        int activityScore = (scoreAdventure * 20).toInt();

        if (activities.isEmpty) {
          if (scoreBeaches > 3) activities.add("Plage");
          if (scoreNature > 3) activities.add("Nature");
          if (scoreCulture > 3) activities.add("Culture");
          if (scoreNightlife > 3) activities.add("Vie nocturne");
          if (activities.isEmpty) activities.add("Tourisme");
        }

        destinations.add(
          Destination(
            id: id,
            name: name,
            country: country,
            continent: continent,
            latitude: latitude,
            longitude: longitude,
            activities: activities,
            averageCost: averageCost,
            climate: climate,
            duration: duration,
            description: description,
            travelTypes: [budgetLevel],
            rating: 4.5,
            annualVisitors: 100000,
            unescoSite: false,
            activityScore: activityScore,
            scoreCulture: scoreCulture,
            scoreAdventure: scoreAdventure,
            scoreNature: scoreNature,
            scoreBeaches: scoreBeaches,
            scoreNightlife: scoreNightlife,
            scoreCuisine: scoreCuisine,
            scoreWellness: scoreWellness,
            scoreUrban: scoreUrban,
            scoreSeclusion: scoreSeclusion,
          ),
        );
      }

      return destinations;
    } catch (e) {
      print("Error loading destinations: $e");
      return [];
    }
  }
}
