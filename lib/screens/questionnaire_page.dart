import 'package:flutter/material.dart';
import '../models/questionnaire_model.dart';
import 'questionnaire_page_temperature.dart';      
import 'questionnaire_page_travel_groupe.dart';     
import 'questionnaire_page_continents.dart';
import 'questionnaire_page_detente_sportif.dart';
import 'questionnaire_page_budget.dart';
import 'recommendations_page.dart';


class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  final PageController _pageController = PageController();
  final UserPreferences userPreferences = UserPreferences();
  int _currentPage = 0;
  
  // Liste des étapes (pages) du questionnaire
  late final List<Widget> _questionnairePages;

  @override
  void initState() {
    super.initState();
    
    _questionnairePages = [
      // Étape 1 : Température
      TemperaturePreferencePage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      
      // Étape 2 : Groupe
      TravelGroupPage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      
      // Étape 3 : Continents
      ContinentSelectionPage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      
      // Étape 4 : Activité
      ActivityTypePage(
        onNext: _nextPage,
        preferences: userPreferences,
      ),
      
      // Étape 5 : Budget (dernière étape)
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

  void _finishQuestionnaire() {
    print('✅ Questionnaire Terminé. Préférences:');
    print(userPreferences.toString());
    
    // Naviguer vers la page de recommandations
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsPage(
          userPreferences: userPreferences,
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
      Navigator.pop(context);
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