class PerformanceStep {
  final String name;
  final int durationMs;
  final double percentage;

  PerformanceStep({
    required this.name,
    required this.durationMs,
    required this.percentage,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'durationMs': durationMs,
        'percentage': percentage,
      };

  factory PerformanceStep.fromJson(Map<String, dynamic> json) =>
      PerformanceStep(
        name: json['name'],
        durationMs: json['durationMs'],
        percentage: json['percentage'],
      );
}

class PerformanceResult {
  final DateTime timestamp;
  final int totalDurationMs;
  final List<PerformanceStep> steps;
  final int? batteryLevelStart;
  final int? batteryLevelEnd;
  final int? batteryDrain;
  final String version; // Pour identifier avant/après optimisation

  PerformanceResult({
    required this.timestamp,
    required this.totalDurationMs,
    required this.steps,
    this.batteryLevelStart,
    this.batteryLevelEnd,
    this.batteryDrain,
    this.version = '1.0',
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'totalDurationMs': totalDurationMs,
        'steps': steps.map((s) => s.toJson()).toList(),
        'batteryLevelStart': batteryLevelStart,
        'batteryLevelEnd': batteryLevelEnd,
        'batteryDrain': batteryDrain,
        'version': version,
      };

  factory PerformanceResult.fromJson(Map<String, dynamic> json) =>
      PerformanceResult(
        timestamp: DateTime.parse(json['timestamp']),
        totalDurationMs: json['totalDurationMs'],
        steps: (json['steps'] as List)
            .map((s) => PerformanceStep.fromJson(s))
            .toList(),
        batteryLevelStart: json['batteryLevelStart'],
        batteryLevelEnd: json['batteryLevelEnd'],
        batteryDrain: json['batteryDrain'],
        version: json['version'] ?? '1.0',
      );

  double get totalDurationSeconds => totalDurationMs / 1000;
}
