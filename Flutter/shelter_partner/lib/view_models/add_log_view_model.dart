import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/add_log_repository.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/views/pages/enrichment_page.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class AddLogViewModel extends StateNotifier<Animal> {
  final AddLogRepository _repository;
  final Ref ref;

  AddLogViewModel(this._repository, this.ref, Animal animal) : super(animal);

  Future<void> addQuickLogToAnimal(Animal animal, Log log) async {
    final logger = ref.read(loggerServiceProvider);
    logger.debug("Adding quick log to animal: ${log.toMap()}");
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    // try {
    await _repository.addLogToAnimal(
      animal,
      shelterDetailsAsync.value!.id,
      log,
    );
    // Optionally, update the state if needed
    //   ref.read(logAddedProvider.notifier).state = true;
    // } catch (e) {
    //   // Handle error
    //   print('Failed to add note: $e');
    // }
  }

  Future<void> addLogToAnimal(Animal animal, Log log) async {
    final logger = ref.read(loggerServiceProvider);
    logger.debug("Adding log to animal: ${log.toMap()}");
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    try {
      await _repository.addLogToAnimal(
        animal,
        shelterDetailsAsync.value!.id,
        log,
      );
      // Optionally, update the state if needed
      ref.read(logAddedProvider.notifier).state = true;
    } catch (e, stackTrace) {
      // Handle error
      final logger = ref.read(loggerServiceProvider);
      logger.error('Failed to add log', e, stackTrace);
    }
  }
}

// Provider for AddNoteViewModel
final addLogViewModelProvider =
    StateNotifierProvider.family<AddLogViewModel, Animal, Animal>((
      ref,
      animal,
    ) {
      final repository = ref.watch(addLogRepositoryProvider);
      return AddLogViewModel(repository, ref, animal);
    });
