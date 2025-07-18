import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/put_back_confirmation_repository.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class PutBackConfirmationViewModel extends StateNotifier<Animal> {
  final PutBackConfirmationRepository _repository;
  final Ref ref;

  PutBackConfirmationViewModel(this._repository, this.ref, Animal animal)
    : super(animal);

  Future<void> putBackAnimal(Animal animal, Log log) async {
    final logger = ref.read(loggerServiceProvider);
    logger.debug("Putting back animal with log: ${log.toMap()}");
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    // final enrichmentViewModel = ref.read(enrichmentViewModelProvider.notifier);

    // enrichmentViewModel.updateAnimalOptimistically(animal.copyWith(inKennel: true));
    try {
      await _repository.putBackAnimal(
        animal,
        shelterDetailsAsync.value!.id,
        log,
      );
      // Optionally, update the state if needed
    } catch (e, stackTrace) {
      // Handle error
      final logger = ref.read(loggerServiceProvider);
      logger.error('Failed to put back animal', e, stackTrace);
    }
  }

  Future<void> bulkPutBackAnimals(List<Animal> animals, List<Log> logs) async {
    final logger = ref.read(loggerServiceProvider);
    logger.debug("Bulk putting back ${animals.length} animals");

    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);

    try {
      await _repository.bulkPutBackAnimals(
        animals,
        shelterDetailsAsync.value!.id,
        logs,
      );
      logger.info('Successfully bulk put back ${animals.length} animals');
    } catch (e, stackTrace) {
      // Handle error
      logger.error('Failed to bulk put back animals', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteLastLog(Animal animal) async {
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);

    try {
      await _repository.deleteLastLog(animal, shelterDetailsAsync.value!.id);
      // Optionally, update the state if needed
    } catch (e, stackTrace) {
      // Handle error
      final logger = ref.read(loggerServiceProvider);
      logger.error('Failed to delete last log', e, stackTrace);
    }
  }

  Future<void> bulkDeleteLastLogs(List<Animal> animals) async {
    final logger = ref.read(loggerServiceProvider);
    logger.debug("Bulk deleting last logs for ${animals.length} animals");

    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);

    try {
      await _repository.bulkDeleteLastLogs(
        animals,
        shelterDetailsAsync.value!.id,
      );
      logger.info(
        'Successfully bulk deleted last logs for ${animals.length} animals',
      );
    } catch (e, stackTrace) {
      // Handle error
      logger.error('Failed to bulk delete last logs', e, stackTrace);
      rethrow;
    }
  }
}

// Provider for AddNoteViewModel
final putBackConfirmationViewModelProvider =
    StateNotifierProvider.family<PutBackConfirmationViewModel, Animal, Animal>((
      ref,
      animal,
    ) {
      final repository = ref.watch(putBackConfirmationRepositoryProvider);
      return PutBackConfirmationViewModel(repository, ref, animal);
    });

// Provider for bulk operations
final bulkPutBackViewModelProvider = Provider<PutBackConfirmationViewModel>((
  ref,
) {
  final repository = ref.watch(putBackConfirmationRepositoryProvider);
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
    inKennel: false,
    intakeDate: null,
    photos: [],
    notes: [],
    logs: [],
    tags: [],
  );
  return PutBackConfirmationViewModel(repository, ref, dummyAnimal);
});
