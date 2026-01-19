import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/performance_result_model.dart';

class PerformanceProfiler {
  static final PerformanceProfiler _instance = PerformanceProfiler._internal();
  factory PerformanceProfiler() => _instance;
  PerformanceProfiler._internal();

  final Battery _battery = Battery();
  final List<_StepMeasurement> _steps = [];
  final Stopwatch _globalStopwatch = Stopwatch();
  int? _batteryStart;
  bool _isRecording = false;

  // Démarre l'enregistrement global
  Future<void> startRecording() async {
    if (_isRecording) return;
    
    _isRecording = true;
    _steps.clear();
    _globalStopwatch.reset();
    _globalStopwatch.start();
    
    try {
      _batteryStart = await _battery.batteryLevel;
    } catch (e) {
      print('⚠️ Impossible de lire le niveau de batterie: $e');
      _batteryStart = null;
    }
    
    print('📊 Enregistrement des performances démarré');
  }

  // Mesure une étape spécifique
  Future<T> measureStep<T>(
    String stepName,
    Future<T> Function() operation,
  ) async {
    if (!_isRecording) {
      return await operation();
    }

    final stepwatch = Stopwatch()..start();
    print('⏱️  Début: $stepName');
    
    try {
      final result = await operation();
      stepwatch.stop();
      
      _steps.add(_StepMeasurement(
        name: stepName,
        durationMs: stepwatch.elapsedMilliseconds,
      ));
      
      print('✓ $stepName: ${stepwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stepwatch.stop();
      print('✗ $stepName échoué après ${stepwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // Termine l'enregistrement et retourne les résultats
  Future<PerformanceResult> stopRecording({String version = '1.0'}) async {
    if (!_isRecording) {
      throw Exception('Aucun enregistrement en cours');
    }

    _globalStopwatch.stop();
    _isRecording = false;

    int? batteryEnd;
    int? batteryDrain;

    try {
      batteryEnd = await _battery.batteryLevel;
      if (_batteryStart != null && batteryEnd != null) {
        batteryDrain = _batteryStart! - batteryEnd;
      }
    } catch (e) {
      print('⚠️ Impossible de lire le niveau de batterie final: $e');
    }

    final totalMs = _globalStopwatch.elapsedMilliseconds;

    // Calculer les pourcentages
    final steps = _steps.map((step) {
      return PerformanceStep(
        name: step.name,
        durationMs: step.durationMs,
        percentage: (step.durationMs / totalMs) * 100,
      );
    }).toList();

    final result = PerformanceResult(
      timestamp: DateTime.now(),
      totalDurationMs: totalMs,
      steps: steps,
      batteryLevelStart: _batteryStart,
      batteryLevelEnd: batteryEnd,
      batteryDrain: batteryDrain,
      version: version,
    );

    // Sauvegarder automatiquement
    await _saveResult(result);

    print('\n📊 === Résumé des performances ===');
    print('Temps total: ${totalMs}ms (${(totalMs / 1000).toStringAsFixed(2)}s)');
    if (batteryDrain != null) {
      print('Batterie consommée: $batteryDrain%');
    }
    print('\nDétail des étapes:');
    for (var step in steps) {
      print('  ${step.name}: ${step.durationMs}ms (${step.percentage.toStringAsFixed(1)}%)');
    }
    print('=====================================\n');

    return result;
  }

  // Sauvegarde un résultat
  Future<void> _saveResult(PerformanceResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await getAllResults();
      results.add(result);
      
      // Garder seulement les 50 derniers résultats
      if (results.length > 50) {
        results.removeRange(0, results.length - 50);
      }
      
      final jsonList = results.map((r) => r.toJson()).toList();
      await prefs.setString('performance_results', jsonEncode(jsonList));
      print('💾 Résultat sauvegardé (${results.length} au total)');
    } catch (e) {
      print('⚠️ Erreur lors de la sauvegarde: $e');
    }
  }

  // Récupère tous les résultats sauvegardés
  Future<List<PerformanceResult>> getAllResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('performance_results');
      
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => PerformanceResult.fromJson(json))
          .toList();
    } catch (e) {
      print('⚠️ Erreur lors de la récupération: $e');
      return [];
    }
  }

  // Récupère les résultats par version
  Future<List<PerformanceResult>> getResultsByVersion(String version) async {
    final all = await getAllResults();
    return all.where((r) => r.version == version).toList();
  }

  // Efface tous les résultats
  Future<void> clearResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('performance_results');
    print('🗑️  Tous les résultats ont été effacés');
  }

  // Statistiques moyennes pour une version
  Future<PerformanceStats?> getAverageStats(String version) async {
    final results = await getResultsByVersion(version);
    
    if (results.isEmpty) return null;

    final avgTotal = results.map((r) => r.totalDurationMs).reduce((a, b) => a + b) / results.length;
    
    // Calculer les moyennes par étape
    final Map<String, List<int>> stepDurations = {};
    for (var result in results) {
      for (var step in result.steps) {
        stepDurations.putIfAbsent(step.name, () => []).add(step.durationMs);
      }
    }

    final avgSteps = stepDurations.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return PerformanceStep(
        name: entry.key,
        durationMs: avg.round(),
        percentage: (avg / avgTotal) * 100,
      );
    }).toList();

    final avgBatteryDrain = results
        .where((r) => r.batteryDrain != null)
        .map((r) => r.batteryDrain!)
        .toList();
    
    final batteryAvg = avgBatteryDrain.isEmpty
        ? null
        : avgBatteryDrain.reduce((a, b) => a + b) / avgBatteryDrain.length;

    return PerformanceStats(
      version: version,
      sampleCount: results.length,
      avgTotalMs: avgTotal.round(),
      avgSteps: avgSteps,
      avgBatteryDrain: batteryAvg,
    );
  }
}

class _StepMeasurement {
  final String name;
  final int durationMs;

  _StepMeasurement({
    required this.name,
    required this.durationMs,
  });
}

class PerformanceStats {
  final String version;
  final int sampleCount;
  final int avgTotalMs;
  final List<PerformanceStep> avgSteps;
  final double? avgBatteryDrain;

  PerformanceStats({
    required this.version,
    required this.sampleCount,
    required this.avgTotalMs,
    required this.avgSteps,
    this.avgBatteryDrain,
  });
}
