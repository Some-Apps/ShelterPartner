import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class LogsWidget extends StatelessWidget {
  final List<Log> logs;
  final bool isAdmin;
  final Function(String logId) onDelete;

  const LogsWidget({
    super.key,
    required this.logs,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (MediaQuery.of(context).size.width / 200).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logs section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Logs',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(),
        logs.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: StaggeredGrid.count(
                  crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  children: List.generate(logs.length, (int index) {
                    final log = logs[index];
                    final startTime = log.startTime.toDate();
                    final endTime = log.endTime.toDate();
                    final duration = endTime.difference(startTime).inMinutes;
                    final formattedDate = endTime != null
                        ? DateFormat('MMM d').format(endTime)
                        : '';

                    return LogCard(
                      log: log,
                      duration: duration,
                      formattedDate: formattedDate,
                      isAdmin: isAdmin,
                      onDelete: () async {
                        // Show confirmation dialog
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                                'Are you sure you want to delete this log?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pop(false), // Do not delete
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pop(true), // Proceed to delete
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          onDelete(log.id);
                        }
                      },
                    );
                  }),
                ),
              )
            : const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No logs available'),
              ),
      ],
    );
  }
}

class LogCard extends StatelessWidget {
  final Log log;
  final int? duration;
  final String formattedDate;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const LogCard({
    super.key,
    required this.log,
    required this.duration,
    required this.formattedDate,
    required this.isAdmin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Author and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Author and Date
                    Row(
                      children: [
                        Text(
                          log.author,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    // Empty space or Log Type (optional)
                    Container(),
                  ],
                ),
                const SizedBox(height: 8.0),
                // Duration
                Text(
                  duration != null ? '$duration minutes' : 'No duration',
                  style: const TextStyle(fontSize: 16.0),
                ),
              ],
            ),
          ),
          // Delete button for admins
          if (isAdmin)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red.withOpacity(0.5),
                  size: 15.0,
                ),
                onPressed: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}
