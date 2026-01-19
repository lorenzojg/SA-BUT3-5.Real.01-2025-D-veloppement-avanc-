import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // ✅ Import de la splash screen

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
      title: 'SérendIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // ✅ Démarrer par la SplashScreen pour l'initialisation des données
      home: const SplashScreen(),
    );
  }
  
}