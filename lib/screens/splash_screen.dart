import 'package:flutter/material.dart';
import 'questionnaire_page.dart';
import 'recommendations_page.dart';
import '../services/preferences_cache_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = false;
  final PreferencesCacheService _cacheService = PreferencesCacheService();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si des préférences existent dans le cache
      final cachedPrefs = await _cacheService.loadPreferences();
      if (cachedPrefs != null && mounted) {
        // Préférences trouvées, naviguer directement vers les recommandations
        print('🚀 Préférences trouvées, navigation directe vers recommandations');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationsPage(
              userPreferences: cachedPrefs,
              isAppStartup: true, // C'est le démarrage de l'app
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur de chargement des préférences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction de navigation
  void _startQuestionnaire() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionnairePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: Stack(
        children: [
          _buildPhotoGrid(),
          _buildMainContent(),
          _buildLogo(),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/images/icon/icon.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.flight, size: 60, color: Colors.white);
              },
            ),
            const SizedBox(height: 30),
            const Text(
              "L'art de s'envoler\nvers l'inattendu...",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
                height: 1.6,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startQuestionnaire,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1a3a52),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  disabledBackgroundColor: Colors.white.withOpacity(0.5),
                ),
                child: Text(
                  _isLoading ? 'Chargement...' : 'Commencer',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholders pour les images de fond
  Widget _buildPhotoGrid() {
    return Opacity(
      opacity: 0.2,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildPhotoItem('assets/images/travel1.jpeg'),
                _buildPhotoItem('assets/images/travel2.jpeg'),
              ],
            ),
          ),
          Expanded(flex: 2, child: Container()),
          Expanded(
            child: Column(
              children: [
                _buildPhotoItem('assets/images/travel3.jpeg'),
                _buildPhotoItem('assets/images/travel4.jpeg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String imagePath) {
    // Si l'image n'existe pas, utilise un Container
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black, // Couleur de remplacement
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) => {},
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const SizedBox.shrink(); // Logo retiré car inclus dans l'icône principale
  }
}