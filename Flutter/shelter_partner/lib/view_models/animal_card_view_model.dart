// view_models/animal_card_view_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/models/shelter_settings.dart';
import 'package:shelter_partner/repositories/animal_card_repository.dart';

class AnimalCardViewModel extends StateNotifier<AsyncValue<void>> {
  final AnimalRepository _repository;
  final String shelterId;
  final String animalType;
  final ShelterSettings shelterSettings;

  AnimalCardViewModel({
    required AnimalRepository repository,
    required this.shelterId,
    required this.animalType,
    required this.shelterSettings,
  }) : _repository = repository,
       super(const AsyncData(null));

  Future<void> handleAutomaticPutBack(Animal animal) async {
    if (!animal.inKennel &&
        shelterSettings.automaticallyPutBackAnimals &&
        _hasBeenOutLongerThanAutomaticPutBackHours(animal)) {
      try {
        // Create updated logs
        final lastLog = animal.logs.last;
        List<Log> updatedLogs = List<Log>.from(animal.logs);

        if (shelterSettings.ignoreVisitWhenAutomaticallyPutBack) {
          // Remove the last log
          updatedLogs.removeLast();
          await _repository.deleteLastLog(shelterId, animalType, animal.id);
        } else {
          // Update the last log's endTime to exactly 1 hour after startTime
          final updatedLastLog = lastLog.copyWith(
            endTime: Timestamp.fromDate(
              lastLog.startTime.toDate().add(const Duration(hours: 1)),
            ),
          );
          updatedLogs[updatedLogs.length - 1] = updatedLastLog;
        }

        // Create updated animal with new inKennel status and logs
        final updatedAnimal = animal.copyWith(
          inKennel: true,
          logs: updatedLogs,
        );

        // Update the animal in Firestore
        await _repository.updateAnimal(shelterId, animalType, updatedAnimal);

        state = const AsyncData(null);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    }
  }

  bool _hasBeenOutLongerThanAutomaticPutBackHours(Animal animal) {
    final lastLog = animal.logs.last;
    final timeOut = DateTime.now()
        .difference(lastLog.startTime.toDate())
        .inHours;
    return timeOut >= shelterSettings.automaticPutBackHours;
  }
}
