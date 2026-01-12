import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';
import '../services/destination_service.dart';

class ClimatPage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const ClimatPage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<ClimatPage> createState() => _ClimatPageState();
}

class _ClimatPageState extends State<ClimatPage> {
  final DestinationService _db = DestinationService();
  
  // Slider value from 0 to 100
  double _temperatureLevel = 50.0;
  
  // Température min et max depuis la DB
  double _minTemp = -10.0;
  double _maxTemp = 40.0;
  bool _loadingRange = true;

  @override
  void initState() {
    super.initState();
    _loadTemperatureRange();
  }

  Future<void> _loadTemperatureRange() async {
    final range = await _db.getTemperatureRange();
    setState(() {
      _minTemp = range['min']!;
      _maxTemp = range['max']!;
      _loadingRange = false;
    });
    print('🌡️ Plage de température: $_minTemp°C à $_maxTemp°C');
  }

  // Convert slider (0-100) to Celsius (minTemp to maxTemp)
  double get _celsiusValue => (_temperatureLevel / 100) * (_maxTemp - _minTemp) + _minTemp;

  String get _temperatureDescription {
    if (_temperatureLevel < 20) return 'Très froid';
    if (_temperatureLevel < 40) return 'Froid / Frais';
    if (_temperatureLevel < 60) return 'Tempéré';
    if (_temperatureLevel < 80) return 'Chaud';
    return 'Très chaud / Tropical';
  }

  String get _temperatureEmoji {
    if (_temperatureLevel < 20) return '❄️';
    if (_temperatureLevel < 40) return '🌤️';
    if (_temperatureLevel < 60) return '☀️';
    if (_temperatureLevel < 80) return '🔥';
    return '🌴';
  }

  Color get _temperatureColor {
    if (_temperatureLevel < 20) return Colors.blue.shade300;
    if (_temperatureLevel < 40) return Colors.cyan.shade300;
    if (_temperatureLevel < 60) return Colors.orange.shade300;
    if (_temperatureLevel < 80) return Colors.deepOrange.shade300;
    return Colors.red.shade300;
  }

  void _nextQuestion() {
    // Save the Celsius value to the preferences for compatibility
    widget.preferences.prefJaugeClimat = _celsiusValue;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adapter le layout pour mobile
            final availableHeight = constraints.maxHeight;
            final isSmallScreen = availableHeight < 700;
            
            return Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildQuestionTitle(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 10 : 20),
                  Expanded(child: _buildThermometer(isSmallScreen)),
                  SizedBox(height: isSmallScreen ? 10 : 20),
                  _buildNextButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionTitle(bool isSmallScreen) {
    return Text(
      'Quelle température préférez-vous ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: isSmallScreen ? 22 : 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThermometer(bool isSmallScreen) {
    if (_loadingRange) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    // Calculer 5 températures équidistantes pour l'affichage
    final tempRange = _maxTemp - _minTemp;
    final step = tempRange / 4; // 5 points = 4 intervalles
    final temp5 = _maxTemp;
    final temp4 = _maxTemp - step;
    final temp3 = _maxTemp - 2 * step;
    final temp2 = _maxTemp - 3 * step;
    final temp1 = _minTemp;
    
    // Espacement adaptatif
    final spacing = isSmallScreen ? 40.0 : 70.0;
    final thermometerHeight = isSmallScreen ? 250.0 : 350.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels de température à gauche
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 70), // Offset pour aligner avec le thermomètre
            _buildTemperatureLabel('${temp5.round()}°', Colors.red.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp4.round()}°', Colors.deepOrange.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp3.round()}°', Colors.orange.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp2.round()}°', Colors.cyan.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp1.round()}°', Colors.blue.shade300, isSmallScreen),
          ],
        ),
        const SizedBox(width: 20),
        // Thermomètre cliquable au centre
        Column(
          children: [
            Container(
              width: isSmallScreen ? 50 : 60,
              height: isSmallScreen ? 50 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _temperatureColor,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  _temperatureEmoji,
                  style: TextStyle(fontSize: isSmallScreen ? 24 : 30),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onVerticalDragUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = details.localPosition;
                
                // Utiliser localPosition qui est relatif au GestureDetector lui-même
                // Inverser : haut = 100%, bas = 0%
                final newValue = 100 - ((localPosition.dy / thermometerHeight) * 100);
                setState(() {
                  _temperatureLevel = newValue.clamp(0.0, 100.0);
                });
              },
              onVerticalDragDown: (details) {
                // Permettre de cliquer directement sur le thermomètre
                final localPosition = details.localPosition;
                final newValue = 100 - ((localPosition.dy / thermometerHeight) * 100);
                setState(() {
                  _temperatureLevel = newValue.clamp(0.0, 100.0);
                });
              },
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 40,
                    height: thermometerHeight,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: thermometerHeight * (_temperatureLevel / 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.blue.shade400,
                          Colors.cyan.shade400,
                          Colors.orange.shade400,
                          Colors.deepOrange.shade400,
                          Colors.red.shade400,
                        ],
                        stops: const [0, 0.25, 0.5, 0.75, 1],
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: isSmallScreen ? 60 : 80,
              height: isSmallScreen ? 60 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _temperatureColor,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  '${_celsiusValue.round()}°',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        // Description à droite (largeur fixe pour éviter le déplacement du thermomètre)
        SizedBox(
          width: 140, // Largeur fixe pour stabiliser le layout
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: thermometerHeight / 2 + 30), // Centrer verticalement
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<String>(_temperatureDescription), // Clé pour détecter le changement
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _temperatureColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _temperatureColor, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _temperatureDescription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureLabel(String degree, Color color, bool isSmallScreen) {
    return Text(
      degree,
      style: TextStyle(
        color: color,
        fontSize: isSmallScreen ? 16 : 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextQuestion,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1a3a52),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text('Suivant'),
    );
  }
}
