import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shelter_partner/view_models/stats_view_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


final speciesColorMap = <String, Color>{
  'cat': Colors.orange,
  'dog': Colors.green,
};

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsViewModelProvider);
    final selectedCategory = ref.watch(categoryProvider);

    // Extract all species from stats to build a legend
    final allSpecies = _extractAllSpecies(stats);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelter Stats'),
      ),
      body: stats.isEmpty
          ? const Center(child: Text('No data available'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Category Dropdown
                  DropdownButton<String?>(
                    value: selectedCategory,
                    hint: const Text('Select a category'),
                    items: [null, 'Species']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category ?? 'None'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      ref.read(categoryProvider.notifier).state = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card.outlined(
                      color: Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Time Since Animals Were Let Out',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: BarChart(
                                BarChartData(
                                  barGroups: _generateBarGroups(stats, selectedCategory),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: const SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(_mapXToInterval(value.toInt())),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: const SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Legend
                            if (selectedCategory == 'Species')
                              _buildLegend(allSpecies),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Extract all species from the stats map.
  Set<String> _extractAllSpecies(Map<String, Map<String, int>> stats) {
    final speciesSet = <String>{};
    for (var categoryCounts in stats.values) {
      speciesSet.addAll(categoryCounts.keys);
    }
    return speciesSet;
  }

  // Build a simple legend widget
  Widget _buildLegend(Set<String> species) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: species.map((specie) {
        final color = speciesColorMap.putIfAbsent(specie, () => _getRandomColor());
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 16, color: color),
            const SizedBox(width: 4),
            Text(specie),
          ],
        );
      }).toList(),
    );
  }

  // A helper to get a random color if new species appear dynamically
  Color _getRandomColor() {
    // In a real scenario, pick from a predefined palette or generate.
    // For simplicity, just return a random Color.
    return Color((0xFF000000 + (0x00FFFFFF * (DateTime.now().millisecond / 1000))).toInt()).withOpacity(1.0);
  }

  List<BarChartGroupData> _generateBarGroups(
    Map<String, Map<String, int>> stats, String? category) {
    final barGroups = <BarChartGroupData>[];

    stats.forEach((timeFrame, categoryCounts) {
      List<BarChartRodData> barRods;
      if (category == null) {
        // Show aggregated count
        final total = categoryCounts.values.isNotEmpty
            ? categoryCounts.values.reduce((a, b) => a + b).toDouble()
            : 0.0;
        barRods = [
          BarChartRodData(
            toY: total,
            width: 30,
            color: Colors.blue,
          ),
        ];
      } else if (category == 'Species') {
        // Show each species separately
        barRods = categoryCounts.entries.map((entry) {
          final speciesName = entry.key;
          final value = entry.value.toDouble();
          final color = speciesColorMap.putIfAbsent(speciesName, () => _getRandomColor());
          return BarChartRodData(
            toY: value,
            width: 15,
            color: color,
          );
        }).toList();
      } else {
        // Filter by some other category if needed
        barRods = categoryCounts.entries
            .where((entry) => entry.key == category)
            .map((entry) => BarChartRodData(
                  toY: entry.value.toDouble(),
                  width: 15,
                  color: Colors.red,
                ))
            .toList();
      }

      barGroups.add(
        BarChartGroupData(
          x: _mapIntervalToX(timeFrame),
          barRods: barRods,
          barsSpace: 5, // Add some space between bars for better readability
        ),
      );
    });

    return barGroups;
  }

  int _mapIntervalToX(String interval) {
    switch (interval) {
      case '<6 hours':
        return 0;
      case '6-24 hours':
        return 1;
      case '1-2 days':
        return 2;
      case '3+ days':
        return 3;
      default:
        return -1;
    }
  }

  String _mapXToInterval(int x) {
    switch (x) {
      case 0:
        return '<6 hours';
      case 1:
        return '6-24 hours';
      case 2:
        return '1-2 days';
      case 3:
        return '3+ days';
      default:
        return '';
    }
  }
}