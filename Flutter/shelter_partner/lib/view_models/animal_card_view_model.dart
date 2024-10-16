// animal_card_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/animal_card_repository.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';

class AnimalCardViewModel extends StateNotifier<Animal> {
  final AnimalCardRepository _repository;
  final Ref ref;

  AnimalCardViewModel(this._repository, this.ref, Animal animal) : super(animal);

  Future<void> toggleInKennel() async {
    // Toggle the inKennel attribute
    final updatedAnimal = state.copyWith(inKennel: !state.inKennel);
    state = updatedAnimal;

    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);

    String? shelterID;
    shelterDetailsAsync.when(
      data: (shelter) {
        shelterID = shelter?.id;
      },
      loading: () {
        shelterID = null;
      },
      error: (error, stack) {
        shelterID = null;
      },
    );

    if (shelterID == null) {
      throw Exception('Shelter ID is not available.');
    }

    // Call the repository to update the database
    await _repository.toggleInKennel(updatedAnimal, shelterID!);
  }
}

// Provider for AnimalCardViewModel
final animalCardViewModelProvider =
    StateNotifierProvider.family<AnimalCardViewModel, Animal, Animal>(
  (ref, animal) {
    final repository = ref.watch(animalCardRepositoryProvider);
    return AnimalCardViewModel(repository, ref, animal);
  },
);
