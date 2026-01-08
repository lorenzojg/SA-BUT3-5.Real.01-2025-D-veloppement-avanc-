import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';
import '../services/database_service_v2.dart';

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
  final DatabaseServiceV2 _db = DatabaseServiceV2();
  
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
    print('🌡️ Plage de température: ${_minTemp}°C à ${_maxTemp}°C');
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
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTemperatureLabel('${temp5.round()}°', 'Tropical', Colors.red.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp4.round()}°', 'Chaud', Colors.deepOrange.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp3.round()}°', 'Tempéré', Colors.orange.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp2.round()}°', 'Frais', Colors.cyan.shade300, isSmallScreen),
            SizedBox(height: spacing),
            _buildTemperatureLabel('${temp1.round()}°', 'Froid', Colors.blue.shade300, isSmallScreen),
          ],
        ),
        const SizedBox(width: 30),
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
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 40,
                  height: isSmallScreen ? 250 : 350,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
                Container(
                  width: 34,
                  height: (isSmallScreen ? 250 : 350) * (_temperatureLevel / 100),
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
                Positioned(
                  bottom: ((isSmallScreen ? 250 : 350) * (_temperatureLevel / 100) - 15).clamp(0, (isSmallScreen ? 235 : 335).toDouble()),
                  child: Container(
                    width: 50,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _temperatureColor, width: 3),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_left,
                          color: Color(0xFF1a3a52), size: 20),
                    ),
                  ),
                ),
              ],
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
        const SizedBox(width: 30),
        SizedBox(
          height: 470,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: _temperatureLevel,
              min: 0,
              max: 100,
              onChanged: (value) {
                setState(() => _temperatureLevel = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureLabel(String degree, String label, Color color, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(degree,
            style: TextStyle(
                color: color, fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 10 : 12)),
      ],
    );
  }

  Widget _buildNextButton() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: _temperatureColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _temperatureColor, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_temperatureEmoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 15),
              Text(
                _temperatureDescription,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
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
        ),
      ],
    );
  }
}
