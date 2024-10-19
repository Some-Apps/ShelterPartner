import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/view_models/add_note_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:uuid/uuid.dart';

class AddNoteView extends ConsumerStatefulWidget {
  final Animal animal;

  const AddNoteView({super.key, required this.animal});

  @override
  _AddNoteViewState createState() => _AddNoteViewState();
}

class _AddNoteViewState extends ConsumerState<AddNoteView> {
  final TextEditingController _noteController = TextEditingController();
  

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetails = ref.read(appUserProvider);


    return AlertDialog(
      title: Text('Add Note for ${widget.animal.name}'),
      content: TextField(
        controller: _noteController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Enter your notes here...',
          border: OutlineInputBorder(),
        ),
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
            Note note = Note(id: const Uuid().v4().toString(), note: _noteController.text, author: ref.read(appUserProvider)!.firstName, timestamp: Timestamp.now());
            ref.read(addNoteViewModelProvider(widget.animal).notifier).addNoteToAnimal(widget.animal, note);
            Navigator.of(context).pop(note);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Usage example
void showAddNoteDialog(BuildContext context, Animal animal) {
  showDialog(
    context: context,
    builder: (context) => AddNoteView(animal: animal),
  ).then((note) {
    if (note != null) {
      // Handle the saved note
      print('Note for ${animal.name}: $note');
    }
  });
}