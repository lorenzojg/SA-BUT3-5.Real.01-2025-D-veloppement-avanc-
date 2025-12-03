import 'package:flutter/material.dart';
// Imports basés sur ton exemple et la version 2.0+
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';

/// Les zones que l'on veut pouvoir sélectionner
enum WorldRegion {
  northAmerica,
  southAmerica,
  europe,
  africa,
  asiaWest, // Moyen-Orient
  asiaEast, // Asie
  oceania,
  unknown,
}

class WorldMapSelector extends StatefulWidget {
  final Function(List<WorldRegion>) onRegionsChanged;

  const WorldMapSelector({Key? key, required this.onRegionsChanged}) : super(key: key);

  @override
  _WorldMapSelectorState createState() => _WorldMapSelectorState();
}

class _WorldMapSelectorState extends State<WorldMapSelector> {
  // Liste des régions sélectionnées
  final Set<WorldRegion> _selectedRegions = {};

  // Configuration des couleurs
  final Color _colorDefault = Colors.grey.shade300; // Gris clair comme dans ton exemple
  final Color _colorSelected = const Color(0xFF1a3a52); // Bleu foncé de ton thème
  final Color _colorOutline = Colors.white;

  /// Quand on clique sur un pays
  void _toggleRegion(String countryId) {
    // La librairie renvoie des ID comme "us", "fr". On utilise notre Helper pour trouver la région.
    WorldRegion region = RegionHelper.getRegion(countryId);

    if (region == WorldRegion.unknown) return;

    setState(() {
      if (_selectedRegions.contains(region)) {
        _selectedRegions.remove(region);
      } else {
        _selectedRegions.add(region);
      }
    });

    // On renvoie la liste au parent
    widget.onRegionsChanged(_selectedRegions.toList());
  }

  /// Génère la liste des couleurs pour la carte
  /// La version 2.0 attend une Map<String, Color> où la clé est le code pays en MINUSCULE.
  Map<String, Color> _generateColorsMap() {
    Map<String, Color> colors = {};
    
    RegionHelper.mapping.forEach((code, region) {
      if (_selectedRegions.contains(region)) {
        // Important : keys en minuscules (ex: 'fr', 'us')
        colors[code.toLowerCase()] = _colorSelected;
      }
    });
    
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 5.0, // Permet de zoomer
      child: SimpleMap(
        // C'est ici qu'on charge la carte du MONDE (et pas Canada comme dans l'exemple)
        instructions: SMapWorld.instructions,
        
        // Couleurs par défaut
        defaultColor: _colorDefault,
        countryBorder: CountryBorder(color: _colorOutline, width: 0.5),
        
        // Application des couleurs dynamiques
        colors: _generateColorsMap(),

        // Gestion du clic
        callback: (id, name, tapDetails) {
          // id = "fr", "us", etc.
          _toggleRegion(id);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER : Associe les codes pays (ISO 2 lettres) aux Régions
// ---------------------------------------------------------------------------
class RegionHelper {
  static WorldRegion getRegion(String countryCode) {
    // On normalise en majuscule
    return mapping[countryCode.toUpperCase()] ?? WorldRegion.unknown;
  }

  static const Map<String, WorldRegion> mapping = {
    // ================== AMÉRIQUE DU NORD ==================
    'US': WorldRegion.northAmerica, 'CA': WorldRegion.northAmerica, // USA, Canada
    'MX': WorldRegion.northAmerica, 'GL': WorldRegion.northAmerica, // Mexique, Groenland
    'BM': WorldRegion.northAmerica, // Bermudes
    // Amérique Centrale
    'BZ': WorldRegion.northAmerica, 'CR': WorldRegion.northAmerica, 
    'SV': WorldRegion.northAmerica, 'GT': WorldRegion.northAmerica, 
    'HN': WorldRegion.northAmerica, 'NI': WorldRegion.northAmerica, 
    'PA': WorldRegion.northAmerica,
    // Caraïbes
    'CU': WorldRegion.northAmerica, 'DO': WorldRegion.northAmerica, 
    'HT': WorldRegion.northAmerica, 'JM': WorldRegion.northAmerica,
    'BS': WorldRegion.northAmerica, 'BB': WorldRegion.northAmerica,
    'PR': WorldRegion.northAmerica, 'TT': WorldRegion.northAmerica,

    // ================== AMÉRIQUE DU SUD ==================
    'AR': WorldRegion.southAmerica, 'BO': WorldRegion.southAmerica,
    'BR': WorldRegion.southAmerica, 'CL': WorldRegion.southAmerica,
    'CO': WorldRegion.southAmerica, 'EC': WorldRegion.southAmerica,
    'FK': WorldRegion.southAmerica, 'GF': WorldRegion.southAmerica, // Malouines, Guyane FR
    'GY': WorldRegion.southAmerica, 'PY': WorldRegion.southAmerica,
    'PE': WorldRegion.southAmerica, 'SR': WorldRegion.southAmerica,
    'UY': WorldRegion.southAmerica, 'VE': WorldRegion.southAmerica,

    // ================== EUROPE ==================
    // Europe de l'Ouest / Nord
    'FR': WorldRegion.europe, 'DE': WorldRegion.europe, 'GB': WorldRegion.europe,
    'IE': WorldRegion.europe, 'BE': WorldRegion.europe, 'NL': WorldRegion.europe,
    'LU': WorldRegion.europe, 'CH': WorldRegion.europe, 'AT': WorldRegion.europe,
    'SE': WorldRegion.europe, 'NO': WorldRegion.europe, 'FI': WorldRegion.europe,
    'DK': WorldRegion.europe, 'IS': WorldRegion.europe,
    // Europe du Sud
    'ES': WorldRegion.europe, 'PT': WorldRegion.europe, 'IT': WorldRegion.europe,
    'GR': WorldRegion.europe, 'MT': WorldRegion.europe, 'CY': WorldRegion.europe,
    // Europe de l'Est / Balkans
    'PL': WorldRegion.europe, 'CZ': WorldRegion.europe, 'SK': WorldRegion.europe,
    'HU': WorldRegion.europe, 'RO': WorldRegion.europe, 'BG': WorldRegion.europe,
    'SI': WorldRegion.europe, 'HR': WorldRegion.europe, 'BA': WorldRegion.europe,
    'RS': WorldRegion.europe, 'ME': WorldRegion.europe, 'MK': WorldRegion.europe,
    'AL': WorldRegion.europe, 'EE': WorldRegion.europe, 'LV': WorldRegion.europe,
    'LT': WorldRegion.europe, 'BY': WorldRegion.europe, 'UA': WorldRegion.europe,
    'MD': WorldRegion.europe, 'RU': WorldRegion.europe, // Russie (souvent classée Europe géo-politiquement)

    // ================== ASIE DE L'OUEST / MOYEN-ORIENT ==================
    'TR': WorldRegion.asiaWest, // Turquie
    'SA': WorldRegion.asiaWest, 'YE': WorldRegion.asiaWest, 'OM': WorldRegion.asiaWest,
    'AE': WorldRegion.asiaWest, 'QA': WorldRegion.asiaWest, 'BH': WorldRegion.asiaWest,
    'KW': WorldRegion.asiaWest, 'IQ': WorldRegion.asiaWest, 'IR': WorldRegion.asiaWest,
    'SY': WorldRegion.asiaWest, 'LB': WorldRegion.asiaWest, 'JO': WorldRegion.asiaWest,
    'IL': WorldRegion.asiaWest, 'PS': WorldRegion.asiaWest,
    'AZ': WorldRegion.asiaWest, 'AM': WorldRegion.asiaWest, 'GE': WorldRegion.asiaWest, // Caucase
    'AF': WorldRegion.asiaWest, 'PK': WorldRegion.asiaWest, // Parfois Asie Sud, ici Ouest pour équilibrer

    // ================== ASIE DE L'EST / SUD / SUD-EST ==================
    'CN': WorldRegion.asiaEast, 'JP': WorldRegion.asiaEast, 'KR': WorldRegion.asiaEast,
    'KP': WorldRegion.asiaEast, 'TW': WorldRegion.asiaEast, 'MN': WorldRegion.asiaEast,
    'IN': WorldRegion.asiaEast, 'BD': WorldRegion.asiaEast, 'LK': WorldRegion.asiaEast,
    'NP': WorldRegion.asiaEast, 'BT': WorldRegion.asiaEast, 'MV': WorldRegion.asiaEast,
    'TH': WorldRegion.asiaEast, 'VN': WorldRegion.asiaEast, 'LA': WorldRegion.asiaEast,
    'KH': WorldRegion.asiaEast, 'MM': WorldRegion.asiaEast, 'MY': WorldRegion.asiaEast,
    'SG': WorldRegion.asiaEast, 'ID': WorldRegion.asiaEast, 'PH': WorldRegion.asiaEast,
    'BN': WorldRegion.asiaEast, 'TL': WorldRegion.asiaEast,
    // Asie Centrale
    'KZ': WorldRegion.asiaEast, 'UZ': WorldRegion.asiaEast, 'TM': WorldRegion.asiaEast,
    'KG': WorldRegion.asiaEast, 'TJ': WorldRegion.asiaEast,

    // ================== AFRIQUE ==================
    // Afrique du Nord
    'DZ': WorldRegion.africa, 'EG': WorldRegion.africa, 'LY': WorldRegion.africa,
    'MA': WorldRegion.africa, 'TN': WorldRegion.africa, 'SD': WorldRegion.africa,
    // Afrique de l'Ouest / Centrale
    'NG': WorldRegion.africa, 'GH': WorldRegion.africa, 'CI': WorldRegion.africa,
    'SN': WorldRegion.africa, 'ML': WorldRegion.africa, 'BF': WorldRegion.africa,
    'NE': WorldRegion.africa, 'GN': WorldRegion.africa, 'LR': WorldRegion.africa,
    'SL': WorldRegion.africa, 'GM': WorldRegion.africa, 'GW': WorldRegion.africa,
    'TG': WorldRegion.africa, 'BJ': WorldRegion.africa, 'CM': WorldRegion.africa,
    'GA': WorldRegion.africa, 'CG': WorldRegion.africa, 'CD': WorldRegion.africa,
    'CF': WorldRegion.africa, 'TD': WorldRegion.africa, 'GQ': WorldRegion.africa,
    // Afrique de l'Est / Sud
    'ET': WorldRegion.africa, 'KE': WorldRegion.africa, 'TZ': WorldRegion.africa,
    'UG': WorldRegion.africa, 'RW': WorldRegion.africa, 'BI': WorldRegion.africa,
    'SO': WorldRegion.africa, 'DJ': WorldRegion.africa, 'ER': WorldRegion.africa,
    'MZ': WorldRegion.africa, 'MG': WorldRegion.africa, 'ZW': WorldRegion.africa,
    'ZM': WorldRegion.africa, 'MW': WorldRegion.africa, 'AO': WorldRegion.africa,
    'NA': WorldRegion.africa, 'BW': WorldRegion.africa, 'ZA': WorldRegion.africa,
    'LS': WorldRegion.africa, 'SZ': WorldRegion.africa,

    // ================== OCÉANIE ==================
    'AU': WorldRegion.oceania, 'NZ': WorldRegion.oceania, 'PG': WorldRegion.oceania,
    'FJ': WorldRegion.oceania, 'SB': WorldRegion.oceania, 'VU': WorldRegion.oceania,
    'NC': WorldRegion.oceania, // Nouvelle Calédonie
    'PF': WorldRegion.oceania, // Polynésie FR
  };
}