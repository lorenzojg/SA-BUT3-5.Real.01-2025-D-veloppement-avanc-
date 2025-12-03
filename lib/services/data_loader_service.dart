import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/destination_model.dart';
import '../models/activity_model.dart';
import 'database_service.dart';

class DataLoaderService {
  static final DataLoaderService _instance = DataLoaderService._internal();

  factory DataLoaderService() {
    return _instance;
  }

  DataLoaderService._internal();

  // ✅ Charger les données CSV et les insérer en base
  Future<void> loadInitialData() async {
    final db = DatabaseService();

    // --- 1. Destinations ---
    final existingDestinations = await db.getAllDestinations();
    
    // Vérification si une mise à jour des données est nécessaire
    bool needsUpdate = false;
    if (existingDestinations.isNotEmpty) {
      if (existingDestinations.first.monthlyFlightPrices == null || existingDestinations.first.monthlyFlightPrices!.isEmpty) {
        needsUpdate = true;
      }
    }

    if (existingDestinations.isEmpty || needsUpdate) {
      if (needsUpdate) {
        print('🔄 Mise à jour des données nécessaire (nouvelles colonnes/données)...');
        await db.clearDestinations();
        await db.clearActivities();
      }

      print('📦 Chargement des destinations depuis les CSV...');
      final destinations = await _loadDestinationsFromCsv();

      for (final destination in destinations) {
        await db.insertDestination(destination);
      }
      print('✅ ${destinations.length} destinations chargées en base');
    } else {
      print('✅ ${existingDestinations.length} destinations déjà en base');
    }

    // --- 2. Activités ---
    bool activitiesLoaded = false;
    // On vérifie s'il y a des activités en base (via la première destination trouvée)
    String? checkCity;
    if (existingDestinations.isNotEmpty) {
      checkCity = existingDestinations.first.name;
    } else {
      // Si on vient de charger, on récupère la liste fraîche
      final newDestinations = await db.getAllDestinations();
      if (newDestinations.isNotEmpty) {
        checkCity = newDestinations.first.name;
      }
    }

    if (checkCity != null) {
       final acts = await db.getActivitiesForDestination(checkCity);
       if (acts.isNotEmpty) {
         activitiesLoaded = true;
       }
    }
    
    if (needsUpdate || !activitiesLoaded) {
       print('📦 Chargement des activités depuis le CSV...');
       await _loadActivitiesFromCsv(db);
       print('✅ Activités chargées en base');
    }
  }

  Future<List<Destination>> _loadDestinationsFromCsv() async {
    try {
      // 1. Charger le Dataset Principal (Base)
      final String worldwideData = await rootBundle.loadString('assets/data/Worldwide_Travel_Cities_Dataset_Ratings_and_Climate.csv');
      List<List<dynamic>> worldwideRows = const CsvToListConverter().convert(worldwideData);

      // 2. Charger City Data (Enrichissement : Climat, Tags, Prix Vols JSON)
      final String cityData = await rootBundle.loadString('assets/data/city_data.csv');
      List<List<dynamic>> cityRows = const CsvToListConverter().convert(cityData);
      
      Map<String, Map<String, dynamic>> cityDataMap = {};
      // Format: input_ville (0), input_pays (1), input_aeroport (2), climat_details (3), 
      // hebergement_moyen_eur_nuit (4), periode_recommandee (5), prix_vol_par_mois (6), tags (7)
      for (var i = 1; i < cityRows.length; i++) {
        var row = cityRows[i];
        if (row.isEmpty) continue;
        String city = row[0].toString().trim();
        
        // Parsing du tableau JSON des prix de vols (colonne 6)
        List<int> flightPrices = [];
        if (row.length > 6) {
          try {
            String jsonStr = row[6].toString();
            // Nettoyage basique si le CSV a ajouté des quotes bizarres
            if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
              jsonStr = jsonStr.substring(1, jsonStr.length - 1);
            }
            jsonStr = jsonStr.replaceAll('""', '"'); // Double quotes escape
            
            var decoded = jsonDecode(jsonStr);
            if (decoded is List) {
              flightPrices = decoded.map((e) => int.tryParse(e.toString()) ?? 0).toList();
            }
          } catch (e) {
            // print('Erreur parsing prix vol pour $city: $e');
          }
        }

        cityDataMap[city] = {
          'climat_details': row.length > 3 ? row[3] : '',
          'hebergement_moyen': row.length > 4 ? row[4] : 0,
          'tags': row.length > 7 ? row[7] : '', // Tags à l'index 7
          'flight_prices': flightPrices,
        };
      }

      // 3. Charger Prix Hotels Spécifiques (Enrichissement Précis)
      // Format: ville (0), pays (1), prix-basse (2), prix-haute (3)
      Map<String, double> hotelPriceMap = {};
      try {
        final String hotelData = await rootBundle.loadString('assets/data/hotel_prices_by_city.csv');
        List<List<dynamic>> hotelRows = const CsvToListConverter().convert(hotelData);
        for (var i = 1; i < hotelRows.length; i++) {
          var row = hotelRows[i];
          if (row.length >= 4) {
            String city = row[0].toString().trim();
            double priceLow = double.tryParse(row[2].toString()) ?? 0.0;
            double priceHigh = double.tryParse(row[3].toString()) ?? 0.0;
            
            // Moyenne des deux saisons
            double avgPrice = 0.0;
            if (priceLow > 0 && priceHigh > 0) {
              avgPrice = (priceLow + priceHigh) / 2;
            } else if (priceLow > 0) {
              avgPrice = priceLow;
            } else {
              avgPrice = priceHigh;
            }
            
            if (avgPrice > 0) {
              hotelPriceMap[city] = avgPrice;
            }
          }
        }
      } catch (e) {
        print("⚠️ Fichier hotel_prices_by_city.csv introuvable ou erreur: $e");
      }

      // 4. Charger Prix Moyens par Pays (Fallback)
      final String prixData = await rootBundle.loadString('assets/data/prixMoyens.csv');
      List<List<dynamic>> prixRows = const CsvToListConverter().convert(prixData);
      Map<String, double> countryCostMap = {};
      for (var i = 1; i < prixRows.length; i++) {
        var row = prixRows[i];
        if (row.length > 3) {
          String country = row[1].toString().trim().toLowerCase();
          double cost = double.tryParse(row[3].toString()) ?? 0.0;
          countryCostMap[country] = cost;
        }
      }

      // 5. Charger Activities (Enrichissement : Noms d'activités spécifiques)
      Map<String, List<String>> activitiesMap = {};
      try {
        final String activitiesData = await rootBundle.loadString('assets/data/activities.csv');
        List<List<dynamic>> activityRows = const CsvToListConverter().convert(activitiesData);
        // Header: address,categories,city,country,description,destination_city,destination_country,destination_id,id,image,latitude,longitude,name,rating,types,wikipedia
        // Index of city: 2 (0-based)
        // Index of name: 12
        for (var i = 1; i < activityRows.length; i++) {
          var row = activityRows[i];
          if (row.length > 12) {
            String city = row[2].toString().trim();
            String name = row[12].toString().trim();
            if (name.isNotEmpty) {
              activitiesMap.putIfAbsent(city, () => []).add(name);
            }
          }
        }
      } catch (e) {
        print("⚠️ Fichier activities.csv introuvable ou erreur: $e");
      }

      // Mapping Pays EN -> FR (pour matcher avec prixMoyens.csv qui est souvent en FR)
      Map<String, String> countryEnToFr = {
        'Italy': 'Italie', 'Fiji': 'Iles Fidji', 'Canada': 'Canada', 'Mexico': 'Mexique',
        'Indonesia': 'Indonésie', 'Greenland': 'Groenland', 'Namibia': 'Namibie',
        'Jamaica': 'Jamaïque', 'Greece': 'Grèce', 'Georgia': 'Géorgie', 'Germany': 'Allemagne',
        'Australia': 'Australie', 'Japan': 'Japon', 'Netherlands': 'Pays-Bas',
        'Myanmar': 'Birmanie', 'Sweden': 'Suède', 'United States': 'Etats-Unis',
        'France': 'France', 'Spain': 'Espagne', 'United Kingdom': 'Royaume Uni',
        'Thailand': 'Thaïlande', 'Vietnam': 'Vietnam', 'India': 'Inde', 'China': 'Chine',
        'Brazil': 'Brésil', 'Argentina': 'Argentine', 'Peru': 'Pérou',
        'South Africa': 'Afrique du Sud', 'Egypt': 'Egypte', 'Morocco': 'Maroc',
        'Turkey': 'Turquie', 'Russia': 'Russie', 'Portugal': 'Portugal',
        'Switzerland': 'Suisse', 'Austria': 'Autriche', 'Belgium': 'Belgique',
        'Ireland': 'Irlande', 'Norway': 'Norvège', 'Denmark': 'Danemark',
        'Finland': 'Finlande', 'Iceland': 'Islande', 'New Zealand': 'Nouvelle Zélande',
        'South Korea': 'Corée du Sud', 'Croatia': 'Croatie', 'Poland': 'Pologne',
        'Chile': 'Chili', 'Colombia': 'Colombie', 'Malaysia': 'Malaisie',
        'Philippines': 'Philippines', 'Singapore': 'Singapour', 'Cambodia': 'Cambodge',
        'Laos': 'Laos', 'Nepal': 'Népal', 'Sri Lanka': 'Sri Lanka', 'Taiwan': 'Taiwan',
        'Jordan': 'Jordanie', 'Oman': 'Oman', 'Qatar': 'Qatar', 'United Arab Emirates': 'Emirats Arabes Unis',
        'Kenya': 'Kenya', 'Tanzania': 'Tanzanie', 'Madagascar': 'Madagascar', 'Mauritius': 'Maurice',
        'Seychelles': 'Seychelles', 'Tunisia': 'Tunisie', 'Senegal': 'Sénégal',
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
        
        // Durée
        String idealDurationsRaw = row[8].toString();
        int duration = 7;
        if (idealDurationsRaw.contains('Weekend')) duration = 3;
        if (idealDurationsRaw.contains('One week')) duration = 7;
        if (idealDurationsRaw.contains('Long trip')) duration = 14;

        String budgetLevel = row[9].toString();
        
        // Scores
        double scoreCulture = (double.tryParse(row[10].toString()) ?? 0.0);
        double scoreAdventure = (double.tryParse(row[11].toString()) ?? 0.0);
        double scoreNature = (double.tryParse(row[12].toString()) ?? 0.0);
        double scoreBeaches = (double.tryParse(row[13].toString()) ?? 0.0);
        double scoreNightlife = (double.tryParse(row[14].toString()) ?? 0.0);
        double scoreCuisine = (double.tryParse(row[15].toString()) ?? 0.0);
        double scoreWellness = (double.tryParse(row[16].toString()) ?? 0.0);
        double scoreUrban = (double.tryParse(row[17].toString()) ?? 0.0);
        double scoreSeclusion = (double.tryParse(row[18].toString()) ?? 0.0);

        // --- Fusion des données ---
        var cityExtra = cityDataMap[name];
        String climate = "Moderate";
        List<String> activities = [];
        List<int> monthlyFlightPrices = [];
        double hotelPricePerNight = 0.0;

        if (cityExtra != null) {
          // Climat
          climate = cityExtra['climat_details'].toString();
          if (climate.length > 150) climate = "${climate.substring(0, 150)}...";
          
          // Tags / Activités
          String tagsRaw = cityExtra['tags'].toString();
          tagsRaw = tagsRaw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", "");
          if (tagsRaw.isNotEmpty) {
            activities = tagsRaw.split(',').map((e) => e.trim()).toList();
          }

          // Ajouter les activités spécifiques depuis activities.csv
          if (activitiesMap.containsKey(name)) {
            activities.addAll(activitiesMap[name]!);
            // Deduplicate
            activities = activities.toSet().toList();
          }

          // Prix Vols
          if (cityExtra['flight_prices'] is List) {
            monthlyFlightPrices = List<int>.from(cityExtra['flight_prices']);
          }
        }

        // Prix Hotel : Priorité 1 (Fichier Hotel), Priorité 2 (City Data), Priorité 3 (Est. Budget)
        if (hotelPriceMap.containsKey(name)) {
          hotelPricePerNight = hotelPriceMap[name]!;
        } else if (cityExtra != null) {
           hotelPricePerNight = double.tryParse(cityExtra['hebergement_moyen'].toString()) ?? 0.0;
        }

        // Calcul Coût Moyen Total (Vol Moyen + Hotel * Durée)
        double avgFlight = 0.0;
        if (monthlyFlightPrices.isNotEmpty) {
          // Moyenne des prix de vol non nuls
          var validPrices = monthlyFlightPrices.where((p) => p > 0);
          if (validPrices.isNotEmpty) {
            avgFlight = validPrices.reduce((a, b) => a + b) / validPrices.length;
          }
        } else {
          // Fallback vol si pas de données
          avgFlight = (continent == 'Europe') ? 200.0 : 800.0;
        }

        // Fallback Hotel si toujours 0
        if (hotelPricePerNight == 0) {
           String countryFr = countryEnToFr[country] ?? country;
           double countryWeeklyCost = countryCostMap[countryFr.toLowerCase()] ?? 0.0;
           if (countryWeeklyCost > 0) {
             hotelPricePerNight = (countryWeeklyCost / 7) * 0.6; // Est. part hotel
           } else {
             // Fallback ultime sur le niveau de budget
             if (budgetLevel == 'Luxury') hotelPricePerNight = 200.0;
             else if (budgetLevel == 'Mid-range') hotelPricePerNight = 100.0;
             else hotelPricePerNight = 50.0;
           }
        }

        double totalAverageCost = avgFlight + (hotelPricePerNight * duration);

        int activityScore = (scoreAdventure * 20).toInt();

        // Fallback activités si vide
        if (activities.isEmpty) {
          if (scoreBeaches > 3) activities.add("Plage");
          if (scoreNature > 3) activities.add("Nature");
          if (scoreCulture > 3) activities.add("Culture");
          if (scoreNightlife > 3) activities.add("Vie nocturne");
          if (activities.isEmpty) activities.add("Tourisme");
        }

        destinations.add(Destination(
          id: id,
          name: name,
          country: country,
          continent: continent,
          latitude: latitude,
          longitude: longitude,
          activities: activities,
          averageCost: totalAverageCost, // Coût total estimé
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
          monthlyFlightPrices: monthlyFlightPrices, // ✅ Données ajoutées
        ));
      }

      return destinations;
    } catch (e, stackTrace) {
      print("❌ Erreur critique lors du chargement des données: $e");
      print(stackTrace);
      return [];
    }
  }

  Future<void> _loadActivitiesFromCsv(DatabaseService db) async {
    try {
      final String csvData = await rootBundle.loadString('assets/data/activities.csv');
      // On découpe manuellement car le format peut être complexe
      List<String> lines = LineSplitter.split(csvData).toList();

      // Ignorer l'en-tête
      if (lines.isNotEmpty) lines.removeAt(0);

      int count = 0;
      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        Activity? activity = _parseActivityLine(line);
        if (activity != null) {
          await db.insertActivity(activity);
          count++;
        }
      }
      print('  ✓ $count activités insérées');
    } catch (e) {
      print('❌ Erreur chargement activités: $e');
    }
  }

  Activity? _parseActivityLine(String line) {
    try {
      List<String> parts = _parseCSVLine(line);
      if (parts.length < 14) return null;

      String categoriesJson = parts[1];
      String city = parts[2].trim();
      String country = parts[3].trim();
      double latitude = double.tryParse(parts[9]) ?? 0.0;
      double longitude = double.tryParse(parts[10]) ?? 0.0;
      String name = parts[11].trim();
      double rating = double.tryParse(parts[12]) ?? 0.0;
      String typesJson = parts[13];

      List<String> categories = _parseJsonArray(categoriesJson);
      List<String> types = _parseJsonArray(typesJson);
      
      bool hasFee = types.contains('fee');
      bool hasWheelchair = types.contains('wheelchair') && types.contains('wheelchair.yes');

      return Activity(
        name: name,
        city: city,
        country: country,
        latitude: latitude,
        longitude: longitude,
        categories: categories,
        rating: rating,
        hasFee: hasFee,
        hasWheelchair: hasWheelchair,
      );
    } catch (e) {
      // print('Erreur parsing ligne activité: $e');
      return null;
    }
  }

  List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  List<String> _parseJsonArray(String jsonString) {
    try {
      String cleaned = jsonString.trim();
      if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }
      cleaned = cleaned.replaceAll('""', '"');
      
      // Si c'est un format Python ['a', 'b']
      cleaned = cleaned.replaceAll("'", '"');
      
      var decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Fallback simple
      if (jsonString.contains(',')) {
        return jsonString.split(',').map((e) => e.trim().replaceAll(RegExp(r"['\[\]]"), "")).toList();
      }
    }
    return [];
  }
}
