// animal_card_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/repositories/add_note_repository.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';

import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class AddNoteViewModel extends StateNotifier<Animal> {
  final AddNoteRepository _repository;
  final Ref ref;
  final LoggerService _logger;

  AddNoteViewModel(this._repository, this.ref, Animal animal)
    : _logger = ref.read(loggerServiceProvider),
      super(animal);

  Future<void> updateAnimalTags(Animal animal, List<String> tags) async {
    try {
      for (var tag in tags) {
        await _repository.updateAnimalTags(
          animal,
          ref.read(shelterDetailsViewModelProvider).value!.id,
          tag,
        );
      }

      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      _logger.error('Failed to add tags', e);
    }
  }

  Future<void> addNoteToAnimal(Animal animal, Note note) async {
    _logger.debug(note.toMap().toString());
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    try {
      await _repository.addNoteToAnimal(
        animal,
        shelterDetailsAsync.value!.id,
        note,
      );
      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      _logger.error('Failed to add note', e);
    }
  }

  Future<void> uploadImageToAnimal(
    Animal animal,
    XFile image,
    WidgetRef ref,
  ) async {
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    try {
      await _repository.uploadImageToAnimal(
        animal,
        shelterDetailsAsync.value!.id,
        image,
        ref,
      );

      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      _logger.error('Failed to upload image', e);
    }
  }
}

// Provider for AddNoteViewModel
final addNoteViewModelProvider =
    StateNotifierProvider.family<AddNoteViewModel, Animal, Animal>((
      ref,
      animal,
    ) {
      final repository = ref.watch(addNoteRepositoryProvider);
      return AddNoteViewModel(repository, ref, animal);
    });
