import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_preferences_model.dart';

/// Service pour sauvegarder et charger les préférences utilisateur
class PreferencesCacheService {
  static const String _prefsKey = 'user_preferences_v2';
  static const String _hasCompletedKey = 'has_completed_questionnaire';

  /// Vérifie si l'utilisateur a déjà complété le questionnaire
  Future<bool> hasCompletedQuestionnaire() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedKey) ?? false;
  }

  /// Sauvegarde les préférences utilisateur
  Future<void> savePreferences(UserPreferencesV2 preferences) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convertir les préférences en JSON
    final json = {
      'selectedContinents': preferences.selectedContinents,
      'minTemperature': preferences.minTemperature,
      'activityLevel': preferences.activityLevel,
      'urbanLevel': preferences.urbanLevel,
      'travelers': preferences.travelers,
      'budgetLevel': preferences.budgetLevel,
      'travelMonth': preferences.travelMonth,
    };
    
    await prefs.setString(_prefsKey, jsonEncode(json));
    await prefs.setBool(_hasCompletedKey, true);
    
    print('✅ Préférences sauvegardées dans le cache');
  }

  /// Charge les préférences utilisateur depuis le cache
  Future<UserPreferencesV2?> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    
    if (jsonString == null) {
      print('ℹ️ Aucune préférence en cache');
      return null;
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final preferences = UserPreferencesV2(
        selectedContinents: List<String>.from(json['selectedContinents']),
        minTemperature: json['minTemperature'],
        activityLevel: json['activityLevel'],
        urbanLevel: json['urbanLevel'],
        travelers: json['travelers'],
        budgetLevel: json['budgetLevel'],
        travelMonth: json['travelMonth'],
      );
      
      print('✅ Préférences chargées depuis le cache');
      return preferences;
    } catch (e) {
      print('❌ Erreur chargement préférences: $e');
      return null;
    }
  }

  /// Efface les préférences (pour recommencer le questionnaire)
  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_hasCompletedKey);
    print('🗑️ Préférences effacées');
  }
}
