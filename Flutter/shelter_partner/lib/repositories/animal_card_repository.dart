// animal_card_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';

class AnimalCardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleInKennel(Animal animal, String shelterID) async {
    // Determine the collection based on species
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';

    // Update the inKennel attribute in Firestore
    await _firestore
        .collection('shelters/$shelterID/$collection')
        .doc(animal.id)
        .update({'inKennel': animal.inKennel});
  }
}

// Provider for AnimalCardRepository
final animalCardRepositoryProvider = Provider<AnimalCardRepository>((ref) {
  return AnimalCardRepository();
});
