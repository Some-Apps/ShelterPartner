import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/repositories/update_volunteer_repository.dart';
import 'package:shelter_partner/view_models/add_note_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/views/pages/enrichment_page.dart';
import 'package:uuid/uuid.dart';

class AddNoteView extends ConsumerStatefulWidget {
  final Animal animal;

  const AddNoteView({super.key, required this.animal});

  @override
  AddNoteViewState createState() => AddNoteViewState();
}

class AddNoteViewState extends ConsumerState<AddNoteView> {
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedTags = {};

  XFile? _selectedImage; // Use XFile instead of File
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final logger = ref.read(loggerServiceProvider);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e, s) {
      logger.error('Error picking image', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetails = ref.read(appUserProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final logger = ref.watch(loggerServiceProvider);

    return AlertDialog(
      title: Text(widget.animal.name),
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
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: FutureBuilder<Uint8List>(
                future: _selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      );
                    } else {
                      return const Text('Failed to load image');
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
          Consumer(
            builder: (context, watch, child) {
              final tags = widget.animal.species == 'dog'
                  ? shelterSettings.value?.shelterSettings.dogTags
                  : shelterSettings.value?.shelterSettings.catTags;
              if (tags == null || tags.isEmpty) {
                return Container(); // Empty container if no tags
              }
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0, // Add vertical spacing
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Add Photo from Gallery'),
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
          onPressed: () async {
            Note note = Note(
              id: const Uuid().v4().toString(),
              note: _noteController.text,
              author: userDetails!.firstName,
              authorID: userDetails.id,
              timestamp: Timestamp.now(),
              // You may need to add a way to store _selectedImage if you plan to save it
            );
            if (note.note.isNotEmpty) {
              logger.debug("adding a note");
              ref
                  .read(addNoteViewModelProvider(widget.animal).notifier)
                  .addNoteToAnimal(widget.animal, note);
            }
            if (_selectedTags.isNotEmpty) {
              logger.debug(_selectedTags.toString());
              ref
                  .read(addNoteViewModelProvider(widget.animal).notifier)
                  .updateAnimalTags(widget.animal, _selectedTags.toList());
            }

            if (_selectedImage != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );

              await ref
                  .read(addNoteViewModelProvider(widget.animal).notifier)
                  .uploadImageToAnimal(widget.animal, _selectedImage!, ref)
                  .then((_) {
                    if (!context.mounted) return;
                    ref
                        .read(updateVolunteerRepositoryProvider)
                        .modifyVolunteerLastActivity(
                          userDetails.id,
                          Timestamp.now(),
                        );
                    Navigator.of(context).pop(); // Close the loading indicator
                    Navigator.of(context).pop(note);
                    ref.read(noteAddedProvider.notifier).state = true;
                  });
            } else {
              ref
                  .read(updateVolunteerRepositoryProvider)
                  .modifyVolunteerLastActivity(userDetails.id, Timestamp.now());
              Navigator.of(context).pop(note);
              ref.read(noteAddedProvider.notifier).state = true;
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
