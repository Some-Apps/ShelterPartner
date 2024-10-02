import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal.dart';

// Provider for AnimalRepository
final animalRepositoryProvider = Provider<AnimalRepository>((ref) {
  return AnimalRepository();
});


class AnimalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Animal>> getAnimalsStream({required String shelterId, required String animalType}) {
    print('Fetching animals from Firestore at path: shelters/$shelterId/$animalType');
    return _firestore.collection('shelters/$shelterId/$animalType').snapshots().map((snapshot) {
      print('Received snapshot: ${snapshot.docs.length} documents');
      return snapshot.docs.map((doc) {
        final animal = Animal.fromDocument(doc);
        print('Parsed animal: ${animal.name}');
        return animal;
      }).toList();
    });
  }
}
