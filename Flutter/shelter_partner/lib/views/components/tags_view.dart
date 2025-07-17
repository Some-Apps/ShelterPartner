import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelter_partner/models/tag.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TagsWidget extends StatelessWidget {
  final List<Tag> tags;
  final bool isAdmin;
  final Function(String tagId) onDelete;

  const TagsWidget({
    super.key,
    required this.tags,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (MediaQuery.of(context).size.width / 200).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Tags', style: Theme.of(context).textTheme.titleLarge),
        ),
        const Divider(),
        tags.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: StaggeredGrid.count(
                  crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  children: List.generate(tags.length, (int index) {
                    final tag = tags[index];
                    final formattedDate = DateFormat(
                      'MMM d',
                    ).format(tag.timestamp.toDate());

                    return Card(
                      elevation: 1,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              16.0,
                              16.0,
                              16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                // Tag title
                                Row(
                                  children: [
                                    Icon(
                                      Icons.label,
                                      size: 16.0,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        tag.title,
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                    ),
                                  ],
                                ),
                                if (tag.count > 1) ...[
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Count: ${tag.count}',
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
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
                                  color: Colors.red.withValues(alpha: 0.5),
                                  size: 15.0,
                                ),
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text(
                                        'Are you sure you want to delete the tag "${tag.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop(false), // Do not delete
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            context,
                                          ).pop(true), // Proceed to delete
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldDelete == true) {
                                    onDelete(tag.id);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              )
            : const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No tags available'),
              ),
      ],
    );
  }
}
