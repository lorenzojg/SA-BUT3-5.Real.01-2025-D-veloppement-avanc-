import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';
import '../models/user_preferences_model.dart';
import '../services/vector_cache_service.dart';
import '../services/preferences_cache_service.dart';
// Importez vos pages personnalisées
import 'questionnaire_page_continents.dart';
import 'questionnaire_page_detente_sportif.dart';
import 'questionnaire_page_budget.dart';
import 'questionnaire_page_travelers.dart';
import 'questionnaire_page_ville_nature.dart';
import 'questionnaire_page_climat.dart';
import 'recommendations_page.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final PageController _pageController = PageController();
  final UserPreferences userPreferences = UserPreferences();
  final VectorCacheService _cacheService = VectorCacheService();
  final PreferencesCacheService _prefsCacheService = PreferencesCacheService();
  int _currentPage = 0;
  
  // Liste des étapes (pages) du questionnaire
  late final List<Widget> _questionnairePages;

  @override
  void initState() {
    super.initState();
    
    // 🚀 Lancer le précalcul des vecteurs en arrière-plan
    print('🚀 Lancement précalcul embeddings pendant le questionnaire...');
    _cacheService.precomputeInBackground();
    
    // Le callback _nextPage permet de passer à la page suivante
    // Le callback _finishQuestionnaire est passé à la dernière étape
    _questionnairePages = [
      // Étape 1 : Continents
      ContinentSelectionPage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      // Étape 2 : Type de Voyageurs (Ajouté)
      TravelersSelectionPage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      // Étape 3 : Ville vs Nature
      VilleNaturePage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      // Étape 4 : Climat
      ClimatPage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      // Étape 5 : Activité
      ActivityTypePage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      // Étape 4 : Budget (la dernière appelle _finishQuestionnaire)
      BudgetSelectionPage(
        onFinish: _finishQuestionnaire,
        preferences: userPreferences,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    // Navigue vers l'étape suivante
    if (_currentPage < _questionnairePages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _finishQuestionnaire() async {
    // Fonction appelée lorsque l'utilisateur a répondu à toutes les questions
    print('✅ Questionnaire Terminé. Préférences:');
    print(userPreferences.toString());
    
    // Convert old UserPreferences to UserPreferencesV2
    final prefsV2 = UserPreferencesV2(
      selectedContinents: userPreferences.selectedContinents,
      minTemperature: userPreferences.prefJaugeClimat,
      activityLevel: userPreferences.activityLevel ?? 50.0,
      urbanLevel: userPreferences.prefJaugeVille * 100,
      travelers: userPreferences.travelers ?? 'En solo',
      budgetLevel: (userPreferences.budgetLevel ?? 2.0),
      travelMonth: DateTime.now().month,
    );
    
    // 💾 Sauvegarder dans le cache
    await _prefsCacheService.savePreferences(prefsV2);
    
    // Naviguer vers la page de recommandations
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsPage(
          userPreferences: prefsV2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a3a52),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a3a52),
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression en haut
            _buildProgressIndicator(),
            
            // Le PageView gère les étapes du questionnaire
            Expanded(
              child: PageView(
                controller: _pageController,
                // Empêche le glissement manuel (on utilise les boutons 'Suivant')
                physics: const NeverScrollableScrollPhysics(), 
                children: _questionnairePages,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    } else {
      Navigator.pop(context); // Retour à la splash screen
    }
  }

  Widget _buildProgressIndicator() {
    final totalPages = _questionnairePages.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / totalPages,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${_currentPage + 1} sur $totalPages',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}