import 'package:flutter/material.dart';
import 'package:shelter_partner/models/animal.dart';


class AddNoteView extends StatefulWidget {
  final Animal animal;

  const AddNoteView({super.key, required this.animal});

  @override
  _AddNoteViewState createState() => _AddNoteViewState();
}

class _AddNoteViewState extends State<AddNoteView> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Handle saving the note here
            String note = _noteController.text;
            // Save the note for the animal
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