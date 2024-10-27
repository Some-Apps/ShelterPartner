// animal_card_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/repositories/add_note_repository.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';

class AddNoteViewModel extends StateNotifier<Animal> {
  final AddNoteRepository _repository;
  final Ref ref;
  

  AddNoteViewModel(this._repository, this.ref, Animal animal) : super(animal);


  Future<void> updateAnimalTags(Animal animal, List<String> tags) async {
    try {
      for (var tag in tags) {
        await _repository.updateAnimalTags(animal, ref.read(shelterDetailsViewModelProvider).value!.id, tag);
      }
      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      print('Failed to add tags: $e');
    }
  }


  Future<void> addNoteToAnimal(Animal animal, Note note) async {
    print(note.toMap());
        // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    try {
      await _repository.addNoteToAnimal(animal, shelterDetailsAsync.value!.id, note);
      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      print('Failed to add note: $e');
    }
  }

 Future<void> uploadImageToAnimal(Animal animal, XFile image) async {
  // Get shelter ID from shelterDetailsViewModelProvider
  final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
  try {
    await _repository.uploadImageToAnimal(animal, shelterDetailsAsync.value!.id, image);
    // Optionally, update the state if needed
  } catch (e) {
    // Handle error
    print('Failed to upload image: $e');
  }
}

  
}

// Provider for AddNoteViewModel
final addNoteViewModelProvider =
    StateNotifierProvider.family<AddNoteViewModel, Animal, Animal>(
  (ref, animal) {
    final repository = ref.watch(addNoteRepositoryProvider);
    return AddNoteViewModel(repository, ref, animal);
  },
);
