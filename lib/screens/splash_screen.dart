import 'package:flutter/material.dart';
import 'questionnaire_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      body: Stack(
        children: [
          // Grille de photos
          _buildPhotoGrid(),

          // Contenu principal
          _buildMainContent(context),

          // Logo en bas
          _buildLogo(),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Opacity(
      opacity: 0.4,
      child: Row(
        children: [
          // Colonne gauche
          Expanded(
            child: Column(
              children: [
                _buildPhotoItem('https://images.unsplash.com/photo-1506012787146-f92b2d7d6d96?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1499678329028-101435549a4e?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400'),
              ],
            ),
          ),
          // Espace central
          Expanded(flex: 2, child: Container()),
          // Colonne droite
          Expanded(
            child: Column(
              children: [
                _buildPhotoItem('https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1505832018823-50331d70d237?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1526772662000-3f88f10405ff?w=400'),
                _buildPhotoItem('https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String imageUrl) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
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
              onPressed: () {
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
              child: const Text(
                'Commencer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
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
