import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/performance_profiler.dart';
import '../models/performance_result_model.dart';

class PerformanceDashboardPage extends StatefulWidget {
  const PerformanceDashboardPage({super.key});

  @override
  State<PerformanceDashboardPage> createState() =>
      _PerformanceDashboardPageState();
}

class _PerformanceDashboardPageState extends State<PerformanceDashboardPage> {
  final _profiler = PerformanceProfiler();
  List<PerformanceResult> _results = [];
  PerformanceStats? _statsV1;
  PerformanceStats? _statsV2;
  bool _isLoading = true;
  String _selectedVersion = '1.0';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await _profiler.getAllResults();
    final statsV1 = await _profiler.getAverageStats('1.0');
    final statsV2 = await _profiler.getAverageStats('2.0');

    setState(() {
      _results = results.reversed.toList();
      _statsV1 = statsV1;
      _statsV2 = statsV2;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearData,
            tooltip: 'Effacer les données',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildVersionSelector(),
                      const SizedBox(height: 20),
                      _buildStatsCard(),
                      const SizedBox(height: 20),
                      _buildPieChart(),
                      const SizedBox(height: 20),
                      _buildBarChart(),
                      const SizedBox(height: 20),
                      if (_statsV1 != null && _statsV2 != null)
                        _buildComparisonCard(),
                      const SizedBox(height: 20),
                      _buildHistoryList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speed, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune mesure disponible',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Lancez un mini-jeu pour collecter des données',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('v1.0 (Actuel)'),
                  selected: _selectedVersion == '1.0',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedVersion = '1.0');
                  },
                ),
                ChoiceChip(
                  label: const Text('v2.0 (Optimisé)'),
                  selected: _selectedVersion == '2.0',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedVersion = '2.0');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats =
        _selectedVersion == '1.0' ? _statsV1 : _statsV2;

    if (stats == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aucune donnée pour v$_selectedVersion',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stats moyennes (${stats.sampleCount} mesures)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStatRow(
              '⏱️ Temps total',
              '${stats.avgTotalMs}ms',
            ),
            if (stats.avgBatteryDrain != null)
              _buildStatRow(
                '🔋 Batterie',
                '${stats.avgBatteryDrain!.toStringAsFixed(1)}%',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final stats = _selectedVersion == '1.0' ? _statsV1 : _statsV2;
    if (stats == null || stats.avgSteps.isEmpty) return const SizedBox.shrink();

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition du temps (%)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    sections: stats.avgSteps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return PieChartSectionData(
                        value: step.percentage,
                        title: '${step.percentage.toStringAsFixed(1)}%',
                        color: colors[index % colors.length],
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: stats.avgSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: colors[index % colors.length],
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${_abbreviateStepName(step.name)} (${step.durationMs}ms)',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final stats = _selectedVersion == '1.0' ? _statsV1 : _statsV2;
    if (stats == null || stats.avgSteps.isEmpty) return const SizedBox.shrink();

    final maxDuration = stats.avgSteps
        .map((s) => s.durationMs)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temps par étape (ms)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: BarChart(
                  BarChartData(
                    maxY: maxDuration * 1.1,
                    barGroups: stats.avgSteps.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.durationMs.toDouble(),
                            color: Colors.deepPurple,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 9),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= stats.avgSteps.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${value.toInt() + 1}',
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Numéros correspondent aux étapes ci-dessus',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _abbreviateStepName(String name) {
    // Retirer les numéros au début ("1. ", "2. ", etc.)
    final nameWithoutNumber = name.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    
    // Si court, retourner tel quel
    if (nameWithoutNumber.length <= 25) return nameWithoutNumber;
    
    // Sinon, tronquer
    return '${nameWithoutNumber.substring(0, 22)}...';
  }

  Widget _buildComparisonCard() {
    if (_statsV1 == null || _statsV2 == null) return const SizedBox.shrink();

    final improvement = _statsV1!.avgTotalMs - _statsV2!.avgTotalMs;
    final improvementPercent =
        (improvement / _statsV1!.avgTotalMs) * 100;

    return Card(
      color: improvement > 0 ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  improvement > 0 ? Icons.trending_up : Icons.trending_down,
                  color: improvement > 0 ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Comparaison v1.0 → v2.0',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildStatRow(
              'v1.0',
              '${_statsV1!.avgTotalMs}ms',
            ),
            _buildStatRow(
              'v2.0',
              '${_statsV2!.avgTotalMs}ms',
            ),
            const Divider(),
            _buildStatRow(
              improvement > 0 ? '✨ Gain' : '⚠️ Perte',
              '${improvement.abs()}ms (${improvementPercent.abs().toStringAsFixed(1)}%)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique (10 dernières)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.take(10).length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final result = _results[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    radius: 16,
                    child: Text(
                      result.version,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    '${result.totalDurationMs}ms',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    _formatDateTime(result.timestamp),
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: result.batteryDrain != null
                      ? Chip(
                          label: Text(
                            '${result.batteryDrain}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                          avatar: const Icon(Icons.battery_alert, size: 14),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  onTap: () => _showResultDetails(result),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} à ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showResultDetails(PerformanceResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${_formatDateTime(result.timestamp)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: ${result.version}'),
              Text('Temps total: ${result.totalDurationMs}ms'),
              if (result.batteryDrain != null)
                Text(
                  'Batterie: ${result.batteryLevelStart}% → ${result.batteryLevelEnd}% (${result.batteryDrain}%)',
                ),
              const Divider(),
              const Text(
                'Étapes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...result.steps.map((step) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(step.name)),
                        Text(
                          '${step.durationMs}ms (${step.percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer les données'),
        content: const Text(
          'Voulez-vous vraiment effacer toutes les mesures de performance ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _profiler.clearResults();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données effacées')),
        );
      }
    }
  }
}
