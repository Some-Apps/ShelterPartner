import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

import 'package:shelter_partner/services/logger_service.dart';

class TakeOutConfirmationRepository {
  final FirebaseFirestore _firestore;
  final LoggerService _logger;
  TakeOutConfirmationRepository({
    required FirebaseFirestore firestore,
    required LoggerService logger,
  }) : _firestore = firestore,
       _logger = logger;

  Future<void> takeOutAnimal(Animal animal, String shelterID, Log log) async {
    try {
      _logger.debug(
        'Starting takeOutAnimal for ${animal.id} in shelter $shelterID',
      );

      // Determine the collection based on species
      final collection = animal.species.toLowerCase() == 'cat'
          ? 'cats'
          : 'dogs';
      _logger.debug('Determined collection: $collection');

      // Combine operations into a single update for better performance
      final updates = <String, dynamic>{'inKennel': false};

      // Only add log if animal is currently in kennel
      if (animal.inKennel) {
        updates['logs'] = FieldValue.arrayUnion([log.toMap()]);
      }

      await _firestore
          .collection('shelters/$shelterID/$collection')
          .doc(animal.id)
          .update(updates);

      _logger.info('Successfully completed takeOutAnimal for ${animal.id}');
    } catch (e) {
      _logger.error('Error in takeOutAnimal', e);
    }
  }

  Future<void> bulkTakeOutAnimals(
    List<Animal> animals,
    String shelterID,
    List<Log> logs,
  ) async {
    if (animals.isEmpty) return;

    try {
      _logger.debug(
        'Starting bulkTakeOutAnimals for ${animals.length} animals in shelter $shelterID',
      );

      final batch = _firestore.batch();

      for (int i = 0; i < animals.length; i++) {
        final animal = animals[i];
        final log = logs[i];

        // Determine the collection based on species
        final collection = animal.species.toLowerCase() == 'cat'
            ? 'cats'
            : 'dogs';

        final docRef = _firestore
            .collection('shelters/$shelterID/$collection')
            .doc(animal.id);

        // Prepare updates for this animal
        final updates = <String, dynamic>{'inKennel': false};

        // Only add log if animal is currently in kennel
        if (animal.inKennel) {
          updates['logs'] = FieldValue.arrayUnion([log.toMap()]);
        }

        batch.update(docRef, updates);
      }

      await batch.commit();
      _logger.info(
        'Successfully completed bulkTakeOutAnimals for ${animals.length} animals',
      );
    } catch (e) {
      _logger.error('Error in bulkTakeOutAnimals', e);
      rethrow;
    }
  }
}

// Provider for AddNoteRepository
final takeOutConfirmationRepositoryProvider =
    Provider<TakeOutConfirmationRepository>((ref) {
      final firestore = ref.watch(firestoreProvider);
      final logger = ref.watch(loggerServiceProvider);
      return TakeOutConfirmationRepository(
        firestore: firestore,
        logger: logger,
      );
    });
