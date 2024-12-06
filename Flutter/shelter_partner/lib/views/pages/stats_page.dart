import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shelter_partner/view_models/stats_view_model.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelter Stats'),
      ),
      body: stats.isEmpty
          ? const Center(child: Text('No data available'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 575,
                child: Card(
                  color: Colors.lightBlue.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                    children: [
                      const Text(
                        'Time Since Animals Were Let Out',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            barGroups: stats.entries
                                .map(
                                  (entry) => BarChartGroupData(
                                    x: _mapIntervalToX(entry.key),
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.toDouble(),
                                        width: 30, // Increased width
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
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
                    ],
                                    ),
                  ),
              ),
            ),
          ),
    );
  }

  int _mapIntervalToX(String interval) {
    switch (interval) {
      case '<1 day':
        return 0;
      case '1-2 days':
        return 1;
      case '3-5 days':
        return 2;
      case '6-7 days':
        return 3;
      case '8+ days':
        return 4;
      default:
        return -1;
    }
  }

  String _mapXToInterval(int x) {
    switch (x) {
      case 0:
        return '<1 day';
      case 1:
        return '1-2 days';
      case 2:
        return '3-5 days';
      case 3:
        return '6-7 days';
      case 4:
        return '8+ days';
      default:
        return '';
    }
  }
}
