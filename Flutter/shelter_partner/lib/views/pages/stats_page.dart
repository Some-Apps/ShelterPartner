import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shelter_partner/view_models/stats_view_model.dart';

// A helper to parse color strings
Color _parseColor(String colorString) {
  switch (colorString.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'grey':
      return Colors.grey;
    case 'gray': // just in case
      return Colors.grey;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    default:
      return Colors.grey; // Default grey if not recognized
  }
}

// For species, just pick some predefined colors:
final speciesColorMap = <String, Color>{
  'cat': Colors.orange,
  'dog': Colors.green,
};

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStats = ref.watch(statsViewModelProvider);
    final selectedCategory = ref.watch(categoryProvider);
    final lastSync = ref.watch(lastSyncProvider);
    final lastEmailSync = ref.watch(lastEmailSyncProvider);
    final recentChanges = ref.watch(recentChangesProvider);

    if (allStats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shelter Stats')),
        body: const Center(child: Text('No data available')),
      );
    }

    if (MediaQuery.of(context).size.width < 500) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shelter Stats')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'View stats on a larger screen or rotate your phone to landscape',
            ),
          ),
        ),
      );
    }

    final categoryKey = selectedCategory == 'Species'
        ? 'Species'
        : selectedCategory == 'Color'
        ? 'Color'
        : 'Species';

    final stats = allStats[categoryKey]!;
    final allKeys = _extractAllKeys(stats);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelter Stats'),
        actions: [
          // Sync status indicator in app bar
          _buildSyncStatusIndicator(lastSync, lastEmailSync, context),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Combined sync status and recent changes card
              if (recentChanges.isNotEmpty ||
                  lastSync != null ||
                  lastEmailSync != null)
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sync status row
                        Row(
                          children: [
                            const Icon(
                              Icons.sync,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (lastSync != null)
                                    _buildSyncRow(
                                      'Last API Sync',
                                      lastSync,
                                      Icons.api,
                                      Colors.green,
                                    ),
                                  if (lastEmailSync != null)
                                    _buildSyncRow(
                                      'Last Email Sync',
                                      lastEmailSync,
                                      Icons.email,
                                      Colors.purple,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (recentChanges.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text(
                            'RECENT ACTIVITIES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: recentChanges.map((change) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        change,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Main content grid
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 2 / 1,
                  crossAxisCount: MediaQuery.of(context).size.width > 1200
                      ? 2
                      : 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                children: [
                  Card.outlined(
                    color: Colors.black.withOpacity(0.025),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Time Since Animals Were Let Out',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Group By: ',
                                overflow: TextOverflow.ellipsis,
                              ),
                              DropdownButton<String?>(
                                value: selectedCategory,
                                hint: const Text('Select'),
                                items: [null, 'Species', 'Color']
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category ?? 'None'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  ref.read(categoryProvider.notifier).state =
                                      value;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          Expanded(
                            child: BarChart(
                              BarChartData(
                                barGroups: _generateBarGroups(
                                  stats,
                                  selectedCategory,
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                _mapXToInterval(value.toInt()),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (selectedCategory == 'Species' ||
                              selectedCategory == 'Color')
                            _buildLegend(allKeys, selectedCategory),
                        ],
                      ),
                    ),
                  ),
                  Card.outlined(
                    color: Colors.black.withOpacity(0.025),
                    child: const Center(
                      child: Text(
                        'Other Stats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Card.outlined(
                    color: Colors.black.withOpacity(0.025),
                    child: const Center(
                      child: Text(
                        'Even More Stats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator(
    DateTime? lastSync,
    String? lastEmailSync,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: 'Sync Status',
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getSyncStatusColor(lastSync, lastEmailSync),
              ),
            ),
            const SizedBox(width: 6),
            Text('Sync', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Color _getSyncStatusColor(DateTime? lastSync, String? lastEmailSync) {
    if (lastSync == null) return Colors.grey;

    final now = DateTime.now();
    final timeSinceLastSync = now.difference(lastSync);

    if (timeSinceLastSync.inHours > 24) return Colors.red;
    if (timeSinceLastSync.inHours > 6) return Colors.orange;
    return Colors.green;
  }

  Widget _buildSyncRow(
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value is DateTime ? _formatDateTime(value) : value.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday at ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, y h:mm a').format(dateTime);
    }
  }

  // Extract all keys (species or color names) from the stats map.
  Set<String> _extractAllKeys(Map<String, Map<String, int>> stats) {
    final keysSet = <String>{};
    for (var categoryCounts in stats.values) {
      keysSet.addAll(categoryCounts.keys);
    }
    return keysSet;
  }

  // Build a simple legend widget
  Widget _buildLegend(Set<String> keys, String? category) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: keys.map((key) {
        Color color;
        if (category == 'Species') {
          // Species color map
          color = speciesColorMap.putIfAbsent(key, () => Colors.blue);
        } else if (category == 'Color') {
          // Parse the color from the string
          color = _parseColor(key);
        } else {
          color = Colors.grey;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 16, color: color),
            const SizedBox(width: 4),
            Text(key),
          ],
        );
      }).toList(),
    );
  }

  List<BarChartGroupData> _generateBarGroups(
    Map<String, Map<String, int>> stats,
    String? category,
  ) {
    final barGroups = <BarChartGroupData>[];

    // If no category selected, show aggregated total
    final showAggregated = (category == null);

    stats.forEach((timeFrame, categoryCounts) {
      List<BarChartRodData> barRods;
      if (showAggregated) {
        // Show aggregated count
        final total = categoryCounts.values.isNotEmpty
            ? categoryCounts.values.reduce((a, b) => a + b).toDouble()
            : 0.0;
        barRods = [BarChartRodData(toY: total, width: 20, color: Colors.black)];
      } else if (category == 'Species') {
        // Show each species separately
        barRods = categoryCounts.entries.map((entry) {
          final name = entry.key;
          final value = entry.value.toDouble();
          final color = speciesColorMap.putIfAbsent(name, () => Colors.blue);
          return BarChartRodData(toY: value, width: 20, color: color);
        }).toList();
      } else if (category == 'Color') {
        // Show each color separately
        barRods = categoryCounts.entries.map((entry) {
          final colorName = entry.key;
          final value = entry.value.toDouble();
          final barColor = _parseColor(colorName);
          return BarChartRodData(toY: value, width: 20, color: barColor);
        }).toList();
      } else {
        // Other categories if added in the future
        barRods = categoryCounts.entries
            .map(
              (entry) => BarChartRodData(
                toY: entry.value.toDouble(),
                width: 20,
                color: Colors.red,
              ),
            )
            .toList();
      }

      barGroups.add(
        BarChartGroupData(
          x: _mapIntervalToX(timeFrame),
          barRods: barRods,
          barsSpace: 5,
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
