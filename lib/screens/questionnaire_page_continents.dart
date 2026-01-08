import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import '../models/questionnaire_model.dart';

class ContinentSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const ContinentSelectionPage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<ContinentSelectionPage> createState() => _ContinentSelectionPageState();
}

class _ContinentSelectionPageState extends State<ContinentSelectionPage> {
  // Map pour stocker l'état de sélection de chaque continent
  final Map<String, bool> selectedContinents = {
    'Afrique': false,
    'Amérique du Nord': false,
    'Amérique du Sud': false,
    'Asie': false,
    'Europe': false,
    'Océanie': false,
  };

  // Couleurs pour la carte
  final Color _colorDefault = Colors.white.withOpacity(0.2);
  final Color _colorSelected = Colors.green;
  final Color _colorOutline = Colors.white.withOpacity(0.5);

  void _toggleContinent(String continent) {
    setState(() {
      selectedContinents[continent] = !selectedContinents[continent]!;
    });
  }

  void _nextQuestion() {
    List<String> selected = selectedContinents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un continent'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.preferences.selectedContinents = selected;
    widget.onNext();
  }

  // Gestion du clic sur un pays de la carte
  void _onCountryTapped(String countryCode) {
    String? continent = _getRegionFromCountryCode(countryCode);
    if (continent != null) {
      _toggleContinent(continent);
    }
  }

  // Convertir le code pays en nom de continent
  String? _getRegionFromCountryCode(String code) {
    final mapping = RegionHelper.mapping[code.toUpperCase()];
    if (mapping == null) return null;

    switch (mapping) {
      case WorldRegion.northAmerica:
        return 'Amérique du Nord';
      case WorldRegion.southAmerica:
        return 'Amérique du Sud';
      case WorldRegion.europe:
        return 'Europe';
      case WorldRegion.africa:
        return 'Afrique';
      case WorldRegion.asiaWest:
      case WorldRegion.asiaEast:
        return 'Asie';
      case WorldRegion.oceania:
        return 'Océanie';
      default:
        return null;
    }
  }

  // Générer les couleurs pour la carte
  Map<String, Color> _generateColorsMap() {
    Map<String, Color> colors = {};

    RegionHelper.mapping.forEach((code, region) {
      String? continent = _getRegionFromCountryCode(code);
      if (continent != null && selectedContinents[continent] == true) {
        colors[code.toLowerCase()] = _colorSelected;
      }
    });

    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 700;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuestionTitle(isSmallScreen),
                  _buildWorldMap(isSmallScreen),
                  _buildContinentLegend(isSmallScreen),
                  _buildNextButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionTitle(bool isSmallScreen) {
    return Text(
      'Avez-vous un continent de\npréférence ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: isSmallScreen ? 20 : 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWorldMap(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 200 : 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1a3a52).withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InteractiveViewer(
          maxScale: 5.0,
          minScale: 0.8,
          child: SimpleMap(
            instructions: SMapWorld.instructions,
            defaultColor: _colorDefault,
            countryBorder: CountryBorder(
              color: _colorOutline,
              width: 0.5,
            ),
            colors: _generateColorsMap(),
            callback: (id, name, tapDetails) {
              _onCountryTapped(id);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContinentLegend(bool isSmallScreen) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: selectedContinents.keys.map((continent) {
        final isSelected = selectedContinents[continent]!;
        return GestureDetector(
          onTap: () => _toggleContinent(continent),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getContinentIcon(continent),
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  continent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getContinentIcon(String continent) {
    switch (continent) {
      case 'Europe':
        return Icons.public;
      case 'Afrique':
        return Icons.castle;
      case 'Amérique du Nord':
        return Icons.deck;
      case 'Amérique du Sud':
        return Icons.park;
      case 'Asie':
        return Icons.temple_hindu;
      case 'Océanie':
        return Icons.beach_access;
      default:
        return Icons.travel_explore;
    }
  }

  Widget _buildNextButton() {
    final hasSelection = selectedContinents.values.any((selected) => selected);

    return Center(
      child: ElevatedButton(
        onPressed: hasSelection ? _nextQuestion : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1a3a52),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          disabledBackgroundColor: Colors.white.withOpacity(0.5),
        ),
        child: const Text(
          'Suivant',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ============================= HELPER CLASS =============================

enum WorldRegion {
  northAmerica,
  southAmerica,
  europe,
  africa,
  asiaWest,
  asiaEast,
  oceania,
  unknown,
}

class RegionHelper {
  static WorldRegion getRegion(String countryCode) {
    return mapping[countryCode.toUpperCase()] ?? WorldRegion.unknown;
  }

  static const Map<String, WorldRegion> mapping = {
    // AMÉRIQUE DU NORD
    'US': WorldRegion.northAmerica, 'CA': WorldRegion.northAmerica,
    'MX': WorldRegion.northAmerica, 'GL': WorldRegion.northAmerica,
    'BM': WorldRegion.northAmerica,
    'BZ': WorldRegion.northAmerica, 'CR': WorldRegion.northAmerica,
    'SV': WorldRegion.northAmerica, 'GT': WorldRegion.northAmerica,
    'HN': WorldRegion.northAmerica, 'NI': WorldRegion.northAmerica,
    'PA': WorldRegion.northAmerica,
    'CU': WorldRegion.northAmerica, 'DO': WorldRegion.northAmerica,
    'HT': WorldRegion.northAmerica, 'JM': WorldRegion.northAmerica,
    'BS': WorldRegion.northAmerica, 'BB': WorldRegion.northAmerica,
    'PR': WorldRegion.northAmerica, 'TT': WorldRegion.northAmerica,

    // AMÉRIQUE DU SUD
    'AR': WorldRegion.southAmerica, 'BO': WorldRegion.southAmerica,
    'BR': WorldRegion.southAmerica, 'CL': WorldRegion.southAmerica,
    'CO': WorldRegion.southAmerica, 'EC': WorldRegion.southAmerica,
    'FK': WorldRegion.southAmerica, 'GF': WorldRegion.southAmerica,
    'GY': WorldRegion.southAmerica, 'PY': WorldRegion.southAmerica,
    'PE': WorldRegion.southAmerica, 'SR': WorldRegion.southAmerica,
    'UY': WorldRegion.southAmerica, 'VE': WorldRegion.southAmerica,

    // EUROPE
    'FR': WorldRegion.europe, 'DE': WorldRegion.europe, 'GB': WorldRegion.europe,
    'IE': WorldRegion.europe, 'BE': WorldRegion.europe, 'NL': WorldRegion.europe,
    'LU': WorldRegion.europe, 'CH': WorldRegion.europe, 'AT': WorldRegion.europe,
    'SE': WorldRegion.europe, 'NO': WorldRegion.europe, 'FI': WorldRegion.europe,
    'DK': WorldRegion.europe, 'IS': WorldRegion.europe, 'SJ': WorldRegion.europe,
    'ES': WorldRegion.europe, 'PT': WorldRegion.europe, 'IT': WorldRegion.europe,
    'GR': WorldRegion.europe, 'MT': WorldRegion.europe, 'CY': WorldRegion.europe,
    'PL': WorldRegion.europe, 'CZ': WorldRegion.europe, 'SK': WorldRegion.europe,
    'HU': WorldRegion.europe, 'RO': WorldRegion.europe, 'BG': WorldRegion.europe,
    'SI': WorldRegion.europe, 'HR': WorldRegion.europe, 'BA': WorldRegion.europe,
    'RS': WorldRegion.europe, 'ME': WorldRegion.europe, 'MK': WorldRegion.europe,
    'AL': WorldRegion.europe, 'EE': WorldRegion.europe, 'LV': WorldRegion.europe,
    'LT': WorldRegion.europe, 'BY': WorldRegion.europe, 'UA': WorldRegion.europe,
    'MD': WorldRegion.europe, 'RU': WorldRegion.europe,

    // ASIE DE L'OUEST
    'TR': WorldRegion.asiaWest,
    'SA': WorldRegion.asiaWest, 'YE': WorldRegion.asiaWest, 'OM': WorldRegion.asiaWest,
    'AE': WorldRegion.asiaWest, 'QA': WorldRegion.asiaWest, 'BH': WorldRegion.asiaWest,
    'KW': WorldRegion.asiaWest, 'IQ': WorldRegion.asiaWest, 'IR': WorldRegion.asiaWest,
    'SY': WorldRegion.asiaWest, 'LB': WorldRegion.asiaWest, 'JO': WorldRegion.asiaWest,
    'IL': WorldRegion.asiaWest, 'PS': WorldRegion.asiaWest,
    'AZ': WorldRegion.asiaWest, 'AM': WorldRegion.asiaWest, 'GE': WorldRegion.asiaWest,
    'AF': WorldRegion.asiaWest, 'PK': WorldRegion.asiaWest,

    // ASIE DE L'EST
    'CN': WorldRegion.asiaEast, 'JP': WorldRegion.asiaEast, 'KR': WorldRegion.asiaEast,
    'KP': WorldRegion.asiaEast, 'TW': WorldRegion.asiaEast, 'MN': WorldRegion.asiaEast,
    'IN': WorldRegion.asiaEast, 'BD': WorldRegion.asiaEast, 'LK': WorldRegion.asiaEast,
    'NP': WorldRegion.asiaEast, 'BT': WorldRegion.asiaEast, 'MV': WorldRegion.asiaEast,
    'TH': WorldRegion.asiaEast, 'VN': WorldRegion.asiaEast, 'LA': WorldRegion.asiaEast,
    'KH': WorldRegion.asiaEast, 'MM': WorldRegion.asiaEast, 'MY': WorldRegion.asiaEast,
    'SG': WorldRegion.asiaEast, 'ID': WorldRegion.asiaEast, 'PH': WorldRegion.asiaEast,
    'BN': WorldRegion.asiaEast, 'TL': WorldRegion.asiaEast,
    'KZ': WorldRegion.asiaEast, 'UZ': WorldRegion.asiaEast, 'TM': WorldRegion.asiaEast,
    'KG': WorldRegion.asiaEast, 'TJ': WorldRegion.asiaEast,

    // AFRIQUE
    'DZ': WorldRegion.africa, 'EG': WorldRegion.africa, 'LY': WorldRegion.africa,
    'MA': WorldRegion.africa, 'TN': WorldRegion.africa, 'SD': WorldRegion.africa,
    'NG': WorldRegion.africa, 'GH': WorldRegion.africa, 'CI': WorldRegion.africa,
    'SN': WorldRegion.africa, 'ML': WorldRegion.africa, 'BF': WorldRegion.africa,
    'NE': WorldRegion.africa, 'GN': WorldRegion.africa, 'LR': WorldRegion.africa,
    'SL': WorldRegion.africa, 'GM': WorldRegion.africa, 'GW': WorldRegion.africa,
    'TG': WorldRegion.africa, 'BJ': WorldRegion.africa, 'CM': WorldRegion.africa,
    'GA': WorldRegion.africa, 'CG': WorldRegion.africa, 'CD': WorldRegion.africa,
    'CF': WorldRegion.africa, 'TD': WorldRegion.africa, 'GQ': WorldRegion.africa,
    'ET': WorldRegion.africa, 'KE': WorldRegion.africa, 'TZ': WorldRegion.africa,
    'UG': WorldRegion.africa, 'RW': WorldRegion.africa, 'BI': WorldRegion.africa,
    'SO': WorldRegion.africa, 'DJ': WorldRegion.africa, 'ER': WorldRegion.africa,
    'MZ': WorldRegion.africa, 'MG': WorldRegion.africa, 'ZW': WorldRegion.africa,
    'ZM': WorldRegion.africa, 'MW': WorldRegion.africa, 'AO': WorldRegion.africa,
    'NA': WorldRegion.africa, 'BW': WorldRegion.africa, 'ZA': WorldRegion.africa,
    'LS': WorldRegion.africa, 'SZ': WorldRegion.africa, 'MR': WorldRegion.africa,
    'EH': WorldRegion.africa, 'SS': WorldRegion.africa,

    // OCÉANIE
    'AU': WorldRegion.oceania, 'NZ': WorldRegion.oceania, 'PG': WorldRegion.oceania,
    'FJ': WorldRegion.oceania, 'SB': WorldRegion.oceania, 'VU': WorldRegion.oceania,
    'NC': WorldRegion.oceania, 'PF': WorldRegion.oceania,
  };
}