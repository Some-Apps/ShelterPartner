import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/view_models/add_note_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:uuid/uuid.dart';

class AddNoteView extends ConsumerStatefulWidget {
  final Animal animal;

  const AddNoteView({super.key, required this.animal});

  @override
  _AddNoteViewState createState() => _AddNoteViewState();
}

class _AddNoteViewState extends ConsumerState<AddNoteView> {
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetails = ref.read(appUserProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);

    return AlertDialog(
      title: Text('Add Note for ${widget.animal.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _noteController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter your notes here...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, watch, child) {
              final tags = widget.animal.species == 'dog'
                  ? shelterSettings.value?.shelterSettings.dogTags
                  : shelterSettings.value?.shelterSettings.catTags;
              if (tags == null || tags.isEmpty) {
                return Container(); // Return an empty container if there are no tags
              }
              return Wrap(
                spacing: 8.0,
                children: tags.map((tag) {
                  return FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Note note = Note(
              id: const Uuid().v4().toString(),
              note: _noteController.text,
              author: ref.read(appUserProvider)!.firstName,
              timestamp: Timestamp.now(),
            );
            ref
                .read(addNoteViewModelProvider(widget.animal).notifier)
                .addNoteToAnimal(widget.animal, note);
            ref
                .read(addNoteViewModelProvider(widget.animal).notifier)
                .updateAnimalTags(widget.animal, _selectedTags.toList());

            Navigator.of(context).pop(note);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
