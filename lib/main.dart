import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'pages/budget_selection_page.dart';
import 'pages/activity_type_page.dart';
=======
import 'screens/splash_screen.dart'; // ✅ Import de la splash screen
import 'screens/questionnaire_page_budget.dart';
import 'screens/questionnaire_page_detente_sportif.dart';
import 'screens/questionnaire_page_continents.dart';
>>>>>>> b9aab2b (grosse modif)

void main() {
  // ✅ Assurer que les Bindings sont initialisés pour Sqflite/Assets
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
<<<<<<< HEAD
      home: const MenuPage(),
    );
  }
}

// Page de menu pour tester vos pages
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a3a52),
        title: const Text('Test des Pages'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choisissez une page à tester',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 40),
            _buildMenuButton(
              context,
              'Budget (Slider €)',
              Icons.euro,
              const BudgetSelectionPage(),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context,
              'Type d\'activité (Détente/Sportif)',
              Icons.beach_access,
              const ActivityTypePage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    IconData icon,
    Widget page,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1a3a52),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 4,
      ),
    );
  }
=======
      // ✅ Démarrer par la SplashScreen pour l'initialisation des données
      home: const SplashScreen(),
    );
  }
>>>>>>> b9aab2b (grosse modif)
}