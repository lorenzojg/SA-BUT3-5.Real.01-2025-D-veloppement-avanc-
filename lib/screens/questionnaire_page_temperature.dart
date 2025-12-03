import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';

class TemperaturePreferencePage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const TemperaturePreferencePage({
    super.key,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<TemperaturePreferencePage> createState() => _TemperaturePreferencePageState();
}

class _TemperaturePreferencePageState extends State<TemperaturePreferencePage> {
  double _temperatureLevel = 50.0; // Valeur par défaut (50 = tempéré)

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
    widget.preferences.temperaturePreference = _temperatureLevel;
    
    print('Préférence de température: $_temperatureLevel - $_temperatureDescription');
    
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuestionTitle(),
              const SizedBox(height: 60),
              _buildThermometer(),
              const SizedBox(height: 50),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle() {
    return const Text(
      'Quelle température préférez-vous ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThermometer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels de température à gauche
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTemperatureLabel('100°', 'Tropical', Colors.red.shade300),
            const SizedBox(height: 70),
            _buildTemperatureLabel('75°', 'Chaud', Colors.deepOrange.shade300),
            const SizedBox(height: 70),
            _buildTemperatureLabel('50°', 'Tempéré', Colors.orange.shade300),
            const SizedBox(height: 70),
            _buildTemperatureLabel('25°', 'Frais', Colors.cyan.shade300),
            const SizedBox(height: 70),
            _buildTemperatureLabel('0°', 'Froid', Colors.blue.shade300),
          ],
        ),
        
        const SizedBox(width: 30),
        
        // Thermomètre vertical
        Column(
          children: [
            // Bulbe du thermomètre en haut (inversé)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _temperatureColor,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _temperatureColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _temperatureEmoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Tube du thermomètre
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Contour du tube
                Container(
                  width: 40,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
                
                // Remplissage coloré (de bas en haut)
                Container(
                  width: 34,
                  height: 400 * (_temperatureLevel / 100),
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
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                
                // Curseur de sélection
                Positioned(
                  bottom: 400 * (_temperatureLevel / 100) - 15,
                  child: Container(
                    width: 50,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _temperatureColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_left,
                        color: Color(0xFF1a3a52),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Base du thermomètre
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _temperatureColor,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _temperatureColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${_temperatureLevel.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 30),
        
        // Slider vertical à droite
        SizedBox(
          height: 470,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 15,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 25,
                ),
                activeTrackColor: _temperatureColor,
                inactiveTrackColor: Colors.white.withOpacity(0.2),
                thumbColor: Colors.white,
                overlayColor: _temperatureColor.withOpacity(0.3),
              ),
              child: Slider(
                value: _temperatureLevel,
                min: 0,
                max: 100,
                onChanged: (value) {
                  setState(() {
                    _temperatureLevel = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureLabel(String degree, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          degree,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
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
              Text(
                _temperatureEmoji,
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 15),
              Text(
                _temperatureDescription,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
            elevation: 4,
          ),
          child: const Text(
            'Suivant',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}