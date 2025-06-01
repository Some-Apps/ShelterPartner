import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class TakeOutConfirmationRepository {
  final FirebaseFirestore _firestore;
  TakeOutConfirmationRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<void> takeOutAnimal(Animal animal, String shelterID, Log log) async {
    try {
      print('Starting takeOutAnimal for ${animal.id} in shelter $shelterID');

      // Determine the collection based on species
      final collection = animal.species.toLowerCase() == 'cat'
          ? 'cats'
          : 'dogs';
      print('Determined collection: $collection');

      // Add the note to the notes attribute in Firestore
      if (animal.inKennel) {
        await _firestore
            .collection('shelters/$shelterID/$collection')
            .doc(animal.id)
            .update({
              'logs': FieldValue.arrayUnion([log.toMap()]),
            });
      }

      print('Updated logs for ${animal.id}');

      await _firestore
          .collection('shelters/$shelterID/$collection')
          .doc(animal.id)
          .update({'inKennel': false});
      print('Updated inKennel status for ${animal.id}');

      print('Successfully completed takeOutAnimal for ${animal.id}');
    } catch (e) {
      print('Error in takeOutAnimal: $e');
    }
  }
}

// Provider for AddNoteRepository
final takeOutConfirmationRepositoryProvider =
    Provider<TakeOutConfirmationRepository>((ref) {
      final firestore = ref.watch(firestoreProvider);
      return TakeOutConfirmationRepository(firestore: firestore);
    });
