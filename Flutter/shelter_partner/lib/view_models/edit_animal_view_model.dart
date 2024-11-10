import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/models/photo.dart';
import 'package:shelter_partner/models/tag.dart';
import 'package:shelter_partner/repositories/edit_animal_repository.dart';
import 'package:collection/collection.dart'; // Add this import

class EditAnimalViewModel extends StateNotifier<Animal> {
  final EditAnimalRepository _repository;
  final Ref ref;

  EditAnimalViewModel(this._repository, this.ref, Animal animal) : super(animal);

  Future<void> deleteItemOptimistically(String shelterId, String animalType, String animalId, String field, String itemId) async {
    dynamic itemToDelete;

    // Capture the item to delete before updating the state
    if (field == 'logs') {
      itemToDelete = state.logs.firstWhereOrNull((log) => log.id == itemId);
      if (itemToDelete != null) {
        List<Log> updatedLogs = List.from(state.logs)..remove(itemToDelete);
        state = state.copyWith(logs: updatedLogs);
      }
    } else if (field == 'notes') {
      itemToDelete = state.notes.firstWhereOrNull((note) => note.id == itemId);
      if (itemToDelete != null) {
        List<Note> updatedNotes = List.from(state.notes)..remove(itemToDelete);
        state = state.copyWith(notes: updatedNotes);
      }
    } else if (field == 'photos') {
      itemToDelete = state.photos?.firstWhereOrNull((photo) => photo.id == itemId);
      if (itemToDelete != null) {
        List<Photo> updatedPhotos = List.from(state.photos ?? [])..remove(itemToDelete);
        state = state.copyWith(photos: updatedPhotos);
      }
    } else if (field == 'tags') {
      itemToDelete = state.tags?.firstWhereOrNull((tag) => tag.id == itemId);
      if (itemToDelete != null) {
        List<Tag> updatedTags = List.from(state.tags ?? [])..remove(itemToDelete);
        state = state.copyWith(tags: updatedTags);
      }
    } else {
      // Unknown field
      return;
    }

    if (itemToDelete == null) {
      // Item not found, nothing to delete
      return;
    }

    try {
      await _repository.deleteItem(shelterId, animalType, animalId, field, itemId);

      // If the item being deleted is a photo, delete it from Firebase Storage
      if (field == 'photos') {
        final photo = itemToDelete as Photo;
        if (photo != null) {
          await _repository.deletePhotoFromStorage(shelterId, animalId, photo.id);
        }
      }
    } catch (e) {
      // Rollback if deletion fails
      // Re-add the item to state
      if (field == 'logs') {
        List<Log> updatedLogs = List.from(state.logs)..add(itemToDelete);
        state = state.copyWith(logs: updatedLogs);
      } else if (field == 'notes') {
        List<Note> updatedNotes = List.from(state.notes)..add(itemToDelete);
        state = state.copyWith(notes: updatedNotes);
      } else if (field == 'photos') {
        List<Photo> updatedPhotos = List.from(state.photos ?? [])..add(itemToDelete);
        state = state.copyWith(photos: updatedPhotos);
      } else if (field == 'tags') {
        List<Tag> updatedTags = List.from(state.tags ?? [])..add(itemToDelete);
        state = state.copyWith(tags: updatedTags);
      }
    }
  }
}

final editAnimalViewModelProvider =
    StateNotifierProvider.family<EditAnimalViewModel, Animal, Animal>(
  (ref, animal) {
    final repository = ref.watch(editAnimalRepositoryProvider);
    return EditAnimalViewModel(repository, ref, animal);
  },
);
