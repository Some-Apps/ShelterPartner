import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

import 'package:shelter_partner/services/logger_service.dart';

class PutBackConfirmationRepository {
  final FirebaseFirestore _firestore;
  final LoggerService _logger;
  PutBackConfirmationRepository({
    required FirebaseFirestore firestore,
    required LoggerService logger,
  }) : _firestore = firestore,
       _logger = logger;

  Future<void> putBackAnimal(Animal animal, String shelterID, Log log) async {
    try {
      // Determine the collection based on species
      final collection = animal.species.toLowerCase() == 'cat'
          ? 'cats'
          : 'dogs';
      _logger.debug('Determined collection: $collection');

      final docRef = _firestore
          .collection('shelters/$shelterID/$collection')
          .doc(animal.id);

      // Only process if animal is not in kennel
      if (!animal.inKennel) {
        // Fetch current logs and update them
        final docSnapshot = await docRef.get();
        final data = docSnapshot.data();
        if (data == null || !data.containsKey('logs')) {
          throw Exception('No logs found for animal ${animal.id}');
        }

        List<dynamic> logs = List.from(data['logs']);
        if (logs.isEmpty) {
          throw Exception('Logs are empty for animal ${animal.id}');
        }

        // Update the last log
        Map<String, dynamic> lastLog = Map.from(logs.last);
        lastLog['earlyReason'] = log.earlyReason;
        lastLog['endTime'] = log.endTime;
        logs[logs.length - 1] = lastLog;

        // Update both logs and inKennel status in a single operation
        await docRef.update({'logs': logs, 'inKennel': true});
        _logger.info('Updated last log and inKennel status for ${animal.id}');
      }
    } catch (e) {
      _logger.error('Error in putBackAnimal', e);
    }
  }

  Future<void> bulkPutBackAnimals(
    List<Animal> animals,
    String shelterID,
    List<Log> logs,
  ) async {
    if (animals.isEmpty) return;

    try {
      _logger.debug(
        'Starting bulkPutBackAnimals for ${animals.length} animals in shelter $shelterID',
      );

      // Use Firestore batch for true batch processing
      final batch = _firestore.batch();

      for (int i = 0; i < animals.length; i++) {
        final animal = animals[i];
        final log = logs[i];

        // Only process if animal is not in kennel
        if (!animal.inKennel) {
          // Determine the collection based on species
          final collection = animal.species.toLowerCase() == 'cat'
              ? 'cats'
              : 'dogs';

          final docRef = _firestore
              .collection('shelters/$shelterID/$collection')
              .doc(animal.id);

          // Create updated logs list with the updated last log
          final updatedLogs = List<Map<String, dynamic>>.from(
            animal.logs.map((existingLog) => existingLog.toMap()),
          );

          if (updatedLogs.isNotEmpty) {
            // Update the last log with the new end time and early reason
            updatedLogs[updatedLogs.length - 1] = {
              ...updatedLogs.last,
              'earlyReason': log.earlyReason,
              'endTime': log.endTime,
            };
          }

          // Add both log and inKennel updates to the batch
          batch.update(docRef, {'logs': updatedLogs, 'inKennel': true});
        }
      }

      // Commit all updates in a single batch operation
      await batch.commit();
      _logger.info(
        'Successfully completed bulkPutBackAnimals for ${animals.length} animals using batch operation',
      );
    } catch (e) {
      _logger.error('Error in bulkPutBackAnimals', e);
      rethrow;
    }
  }

  Future<void> bulkDeleteLastLogs(
    List<Animal> animals,
    String shelterID,
  ) async {
    if (animals.isEmpty) return;

    try {
      _logger.debug(
        'Starting bulkDeleteLastLogs for ${animals.length} animals in shelter $shelterID',
      );

      // Use Firestore batch for true batch processing
      final batch = _firestore.batch();

      for (final animal in animals) {
        // Determine the collection based on species
        final collection = animal.species.toLowerCase() == 'cat'
            ? 'cats'
            : 'dogs';

        final docRef = _firestore
            .collection('shelters/$shelterID/$collection')
            .doc(animal.id);

        // Create updated logs list without the last log
        final updatedLogs = List<Map<String, dynamic>>.from(
          animal.logs.map((existingLog) => existingLog.toMap()),
        );

        if (updatedLogs.isNotEmpty) {
          updatedLogs.removeLast();
        }

        // Add both log and inKennel updates to the batch
        batch.update(docRef, {'logs': updatedLogs, 'inKennel': true});
      }

      // Commit all updates in a single batch operation
      await batch.commit();
      _logger.info(
        'Successfully completed bulkDeleteLastLogs for ${animals.length} animals using batch operation',
      );
    } catch (e) {
      _logger.error('Error in bulkDeleteLastLogs', e);
      rethrow;
    }
  }

  Future<void> deleteLastLog(Animal animal, String shelterID) async {
    try {
      // Determine the collection based on species
      final collection = animal.species.toLowerCase() == 'cat'
          ? 'cats'
          : 'dogs';
      _logger.debug('Determined collection: $collection');

      // Fetch the current logs
      final docRef = _firestore
          .collection('shelters/$shelterID/$collection')
          .doc(animal.id);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null || !data.containsKey('logs')) {
        throw Exception('No logs found for animal ${animal.id}');
      }

      List<dynamic> logs = data['logs'];
      if (logs.isEmpty) {
        throw Exception('Logs are empty for animal ${animal.id}');
      }

      // Remove the last log
      logs.removeLast();

      // Update the logs array and inKennel status in Firestore
      await docRef.update({'logs': logs, 'inKennel': true});
      _logger.info(
        'Deleted last log and set inKennel to true for ${animal.id}',
      );
    } catch (e) {
      _logger.error('Error in deleteLastLog', e);
    }
  }
}

// Provider for PutBackConfirmationRepository
final putBackConfirmationRepositoryProvider =
    Provider<PutBackConfirmationRepository>((ref) {
      final firestore = ref.watch(firestoreProvider);
      final logger = ref.watch(loggerServiceProvider);
      return PutBackConfirmationRepository(
        firestore: firestore,
        logger: logger,
      );
    });
