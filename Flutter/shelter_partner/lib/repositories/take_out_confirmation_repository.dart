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

      // Add the note to the notes attribute in Firestore
      if (animal.inKennel) {
        await _firestore
            .collection('shelters/$shelterID/$collection')
            .doc(animal.id)
            .update({
              'logs': FieldValue.arrayUnion([log.toMap()]),
            });
      }

      _logger.info('Updated logs for ${animal.id}');

      await _firestore
          .collection('shelters/$shelterID/$collection')
          .doc(animal.id)
          .update({'inKennel': false});
      _logger.info('Updated inKennel status for ${animal.id}');

      _logger.info('Successfully completed takeOutAnimal for ${animal.id}');
    } catch (e) {
      _logger.error('Error in takeOutAnimal', e);
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
