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
