import 'package:flutter/material.dart';
import 'questionnaire_page.dart';
import '../services/data_loader_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
    });

    final dataLoader = DataLoaderService();
    try {
      await dataLoader.loadInitialData();
      print('✅ Initialisation terminée');
    } catch (e) {
      print('❌ Erreur d\'initialisation: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: Stack(
        children: [
          _buildPhotoGrid(),
          _buildMainContent(context),
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

  Widget _buildMainContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight, size: 60, color: Colors.white),
            const SizedBox(height: 30),
            const Text(
              "L'art de découvrir\nsans chercher...",
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
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuestionnairePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1a3a52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: Text(
                _isLoading ? 'Chargement...' : 'Commencer',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... reste du code (buildPhotoGrid, buildLogo)

  Widget _buildPhotoGrid() {
    return Opacity(
      opacity: 0.4,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildPhotoItem('assets/images/travel1.jpeg'),
                _buildPhotoItem('assets/images/travel2.jpeg'),
                _buildPhotoItem('assets/images/travel3.jpeg'),
                _buildPhotoItem('assets/images/travel4.jpeg'),
                _buildPhotoItem('assets/images/travel5.jpeg'),
              ],
            ),
          ),
          Expanded(flex: 2, child: Container()),
          Expanded(
            child: Column(
              children: [
                _buildPhotoItem('assets/images/travel6.jpeg'),
                _buildPhotoItem('assets/images/travel7.jpeg'),
                _buildPhotoItem('assets/images/travel8.jpeg'),
                _buildPhotoItem('assets/images/travel9.jpeg'),
                _buildPhotoItem('assets/images/travel10.jpeg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String imagePath) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Serendia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
