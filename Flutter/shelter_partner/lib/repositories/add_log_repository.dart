import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class AddLogRepository {
  final FirebaseFirestore _firestore;
  AddLogRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<void> addLogToAnimal(Animal animal, String shelterID, Log log) async {
    // Determine the collection based on species
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';

    // Add the note to the notes attribute in Firestore
    await _firestore
        .collection('shelters/$shelterID/$collection')
        .doc(animal.id)
        .update({
      'logs': FieldValue.arrayUnion([log.toMap()])
    });
  }
}

// Provider for AddNoteRepository
final addLogRepositoryProvider = Provider<AddLogRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AddLogRepository(firestore: firestore);
});
