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

      // We need to process these in smaller batches due to Firestore read requirements
      // For put back, we need to read current logs first, so we'll process in parallel
      // but not in a single batch operation

      final futures = <Future<void>>[];

      for (int i = 0; i < animals.length; i++) {
        final animal = animals[i];
        final log = logs[i];

        futures.add(_putBackSingleAnimal(animal, shelterID, log));
      }

      await Future.wait(futures);
      _logger.info(
        'Successfully completed bulkPutBackAnimals for ${animals.length} animals',
      );
    } catch (e) {
      _logger.error('Error in bulkPutBackAnimals', e);
      rethrow;
    }
  }

  Future<void> _putBackSingleAnimal(
    Animal animal,
    String shelterID,
    Log log,
  ) async {
    // Determine the collection based on species
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';

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

      List<dynamic> animalLogs = List.from(data['logs']);
      if (animalLogs.isEmpty) {
        throw Exception('Logs are empty for animal ${animal.id}');
      }

      // Update the last log
      Map<String, dynamic> lastLog = Map.from(animalLogs.last);
      lastLog['earlyReason'] = log.earlyReason;
      lastLog['endTime'] = log.endTime;
      animalLogs[animalLogs.length - 1] = lastLog;

      // Update both logs and inKennel status in a single operation
      await docRef.update({'logs': animalLogs, 'inKennel': true});
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

      // Process deletions in parallel
      final futures = <Future<void>>[];

      for (final animal in animals) {
        futures.add(_deleteLastLogSingle(animal, shelterID));
      }

      await Future.wait(futures);
      _logger.info(
        'Successfully completed bulkDeleteLastLogs for ${animals.length} animals',
      );
    } catch (e) {
      _logger.error('Error in bulkDeleteLastLogs', e);
      rethrow;
    }
  }

  Future<void> _deleteLastLogSingle(Animal animal, String shelterID) async {
    // Determine the collection based on species
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';

    final docRef = _firestore
        .collection('shelters/$shelterID/$collection')
        .doc(animal.id);

    // Fetch current logs
    final docSnapshot = await docRef.get();
    final data = docSnapshot.data();
    if (data == null || !data.containsKey('logs')) {
      throw Exception('No logs found for animal ${animal.id}');
    }

    List<dynamic> animalLogs = List.from(data['logs']);
    if (animalLogs.isEmpty) {
      throw Exception('Logs are empty for animal ${animal.id}');
    }

    // Remove the last log
    animalLogs.removeLast();

    // Update the logs array and inKennel status in a single operation
    await docRef.update({'logs': animalLogs, 'inKennel': true});
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
