import 'package:flutter/material.dart';
<<<<<<< HEAD

class ActivityTypePage extends StatefulWidget {
  const ActivityTypePage({super.key});
=======
import '../models/questionnaire_model.dart'; // Importez le modèle

class ActivityTypePage extends StatefulWidget {
  final VoidCallback onNext;
  final UserPreferences preferences;

  const ActivityTypePage({
    super.key,
    required this.onNext,
    required this.preferences,
  });
>>>>>>> b9aab2b (grosse modif)

  @override
  State<ActivityTypePage> createState() => _ActivityTypePageState();
}

class _ActivityTypePageState extends State<ActivityTypePage> {
  double _activityLevel = 50.0; // Valeur par défaut (50 = équilibre)

  String get _activityDescription {
    if (_activityLevel < 20) return 'Très détente';
    if (_activityLevel < 40) return 'Plutôt détente';
    if (_activityLevel < 60) return 'Équilibré';
    if (_activityLevel < 80) return 'Plutôt sportif';
    return 'Très sportif';
  }

  void _nextQuestion() {
<<<<<<< HEAD
    print('Niveau d\'activité sélectionné: $_activityLevel - $_activityDescription');

    // TODO: Navigation vers la prochaine question
    // Navigator.push(context, MaterialPageRoute(builder: (context) => NextPage()));
=======
    // ✅ Sauvegarder les données dans l'objet de préférences
    widget.preferences.activityLevel = _activityLevel;
    
    print('Niveau d\'activité sélectionné: $_activityLevel - $_activityDescription');
    
    // Appeler le callback de navigation
    widget.onNext();
>>>>>>> b9aab2b (grosse modif)
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
<<<<<<< HEAD
              const SizedBox(height: 40),
              _buildImageComparison(),
              const SizedBox(height: 30),
              _buildActivityDescription(),
              const SizedBox(height: 60),
=======
              const SizedBox(height: 50),
              _buildActivitySlider(),
              const SizedBox(height: 50),
>>>>>>> b9aab2b (grosse modif)
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTitle() {
    return const Text(
<<<<<<< HEAD
      'Quel type de vacances préférez-vous ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.4,
=======
      'Quel type de vacances recherchez-vous ?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
>>>>>>> b9aab2b (grosse modif)
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildImageComparison() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Image de détente (gauche)
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.orange.withOpacity(0.3),
                    child: const Center(
                      child: Icon(Icons.beach_access, size: 80, color: Colors.white),
                    ),
                  );
                },
              ),
            ),

            // Image sportive (droite) avec clip
            Positioned.fill(
              child: ClipRect(
                clipper: _RightClipper(_activityLevel / 100),
                child: Image.network(
                  'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.blue.withOpacity(0.3),
                      child: const Center(
                        child: Icon(Icons.directions_run, size: 80, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Ligne de séparation verticale
            Positioned(
              left: (_activityLevel / 100) * MediaQuery.of(context).size.width * 0.85,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Curseur circulaire
            Positioned(
              left: (_activityLevel / 100) * MediaQuery.of(context).size.width * 0.85 - 20,
              top: 140,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  color: Color(0xFF1a3a52),
                ),
              ),
            ),

            // Labels sur les images
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🏖️ DÉTENTE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 20,
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🏃 SPORTIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityDescription() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            trackHeight: 6,
          ),
          child: Slider(
            value: _activityLevel,
            min: 0,
            max: 100,
            onChanged: (value) {
              setState(() {
                _activityLevel = value;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
=======
  Widget _buildActivitySlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Détente', style: TextStyle(color: Colors.white)),
            Text('Sportif', style: TextStyle(color: Colors.white)),
          ],
        ),
        Slider(
          value: _activityLevel,
          min: 0,
          max: 100,
          divisions: 100,
          label: _activityLevel.round().toString(),
          activeColor: Colors.white,
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: (double value) {
            // ✅ Mettre à jour l'état du curseur
            setState(() {
              _activityLevel = value;
            });
          },
        ),
        const SizedBox(height: 30),
>>>>>>> b9aab2b (grosse modif)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _activityDescription,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
        elevation: 4,
      ),
      child: const Text(
<<<<<<< HEAD
        'Question suivante',
=======
        'Suivant',
>>>>>>> b9aab2b (grosse modif)
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
<<<<<<< HEAD
}

// Clipper personnalisé pour afficher la partie droite de l'image
class _RightClipper extends CustomClipper<Rect> {
  final double position;

  _RightClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      size.width * position,
      0,
      size.width,
      size.height,
    );
  }

  @override
  bool shouldReclip(_RightClipper oldClipper) {
    return oldClipper.position != position;
  }
=======
>>>>>>> b9aab2b (grosse modif)
}