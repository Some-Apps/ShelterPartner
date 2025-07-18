// repositories/animal_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class AnimalRepository {
  final FirebaseFirestore _firestore;
  AnimalRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<void> updateAnimal(
    String shelterId,
    String animalType,
    Animal animal,
  ) async {
    await _firestore
        .collection('shelters')
        .doc(shelterId)
        .collection(animalType == 'cat' ? 'cats' : 'dogs')
        .doc(animal.id)
        .set(animal.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteLastLog(
    String shelterId,
    String animalType,
    String animalId,
  ) async {
    DocumentReference animalDocRef = _firestore
        .collection('shelters')
        .doc(shelterId)
        .collection(animalType == 'cat' ? 'cats' : 'dogs')
        .doc(animalId);

    DocumentSnapshot animalSnapshot = await animalDocRef.get();
    if (animalSnapshot.exists) {
      List<dynamic> logs =
          (animalSnapshot.data() as Map<String, dynamic>)['logs'];
      if (logs.isNotEmpty) {
        logs.removeLast();
        await animalDocRef.update({'logs': logs});
      }
    }
  }

  Future<void> markAnimalAsInactive(
    String shelterId,
    String animalType,
    String animalId,
  ) async {
    await _firestore
        .collection('shelters')
        .doc(shelterId)
        .collection(animalType == 'cat' ? 'cats' : 'dogs')
        .doc(animalId)
        .update({'isActive': false});
  }
}

final animalRepositoryProvider = Provider<AnimalRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AnimalRepository(firestore: firestore);
});
