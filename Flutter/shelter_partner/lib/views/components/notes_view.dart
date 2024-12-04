import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class NotesWidget extends StatelessWidget {
  final List<Note> notes;
  final bool isAdmin;
  final Function(String noteId) onDelete;

  const NotesWidget({
    super.key,
    required this.notes,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = (MediaQuery.of(context).size.width / 200).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notes section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Notes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(),
        notes.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: StaggeredGrid.count(
                  crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  children: List.generate(notes.length, (int index) {
                    final note = notes[index];
                    final formattedDate =
                        DateFormat('MMM d').format(note.timestamp.toDate());

                    return Card(
                      elevation: 1,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
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
                                // Note content
                                Text(
                                  note.note,
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
                                onPressed: () async {
                                  // Show confirmation dialog
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this note?'),
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
                                    onDelete(note.id);
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
                child: Text('No notes available'),
              ),
      ],
    );
  }
}

