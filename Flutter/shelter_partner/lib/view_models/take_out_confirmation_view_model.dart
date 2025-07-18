// animal_card_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/take_out_confirmation_repository.dart';
import 'package:shelter_partner/view_models/enrichment_view_model.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class TakeOutConfirmationViewModel extends StateNotifier<Animal> {
  final TakeOutConfirmationRepository _repository;
  final Ref ref;

  TakeOutConfirmationViewModel(this._repository, this.ref, Animal animal)
    : super(animal);

  Future<void> takeOutAnimal(Animal animal, Log log) async {
    final logger = ref.read(loggerServiceProvider);
    logger.debug("Taking out animal with log: ${log.toMap()}");
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    final enrichmentViewModel = ref.read(enrichmentViewModelProvider.notifier);

    enrichmentViewModel.updateAnimalOptimistically(
      animal.copyWith(inKennel: false, logs: [...animal.logs, log]),
    );

    try {
      await _repository.takeOutAnimal(
        animal,
        shelterDetailsAsync.value!.id,
        log,
      );
      // Optionally, update the state if needed
    } catch (e, stackTrace) {
      // Handle error
      final logger = ref.read(loggerServiceProvider);
      logger.error('Failed to take out animal', e, stackTrace);
    }
  }

  Future<void> bulkTakeOutAnimals(List<Animal> animals, List<Log> logs) async {
    final logger = ref.read(loggerServiceProvider);
    logger.debug("Bulk taking out ${animals.length} animals");

    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    final enrichmentViewModel = ref.read(enrichmentViewModelProvider.notifier);

    // Optimistically update all animals in the UI
    for (int i = 0; i < animals.length; i++) {
      final animal = animals[i];
      final log = logs[i];
      enrichmentViewModel.updateAnimalOptimistically(
        animal.copyWith(inKennel: false, logs: [...animal.logs, log]),
      );
    }

    try {
      await _repository.bulkTakeOutAnimals(
        animals,
        shelterDetailsAsync.value!.id,
        logs,
      );
      logger.info('Successfully bulk took out ${animals.length} animals');
    } catch (e, stackTrace) {
      // Handle error - revert optimistic updates if needed
      logger.error('Failed to bulk take out animals', e, stackTrace);
      rethrow;
    }
  }
}

// Provider for AddNoteViewModel
final takeOutConfirmationViewModelProvider =
    StateNotifierProvider.family<TakeOutConfirmationViewModel, Animal, Animal>((
      ref,
      animal,
    ) {
      final repository = ref.watch(takeOutConfirmationRepositoryProvider);
      return TakeOutConfirmationViewModel(repository, ref, animal);
    });

// Provider for bulk operations
final bulkTakeOutViewModelProvider = Provider<TakeOutConfirmationViewModel>((
  ref,
) {
  final repository = ref.watch(takeOutConfirmationRepositoryProvider);
  // Use a dummy animal since we're only using bulk operations
  final dummyAnimal = Animal(
    id: 'bulk',
    name: 'bulk',
    species: 'dog',
    sex: 'male',
    monthsOld: 12,
    breed: 'unknown',
    location: 'unknown',
    fullLocation: 'unknown',
    description: '',
    symbol: '',
    symbolColor: '',
    takeOutAlert: '',
    putBackAlert: '',
    adoptionCategory: 'available',
    behaviorCategory: '',
    locationCategory: '',
    medicalCategory: '',
    volunteerCategory: '',
    inKennel: true,
    intakeDate: null,
    photos: [],
    notes: [],
    logs: [],
    tags: [],
  );
  return TakeOutConfirmationViewModel(repository, ref, dummyAnimal);
});
