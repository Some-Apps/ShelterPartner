import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/animal.dart';

/// Helper to create an animal in Firestore for tests.
Future<void> addAnimalToFirestore({
  required FirebaseFirestore firestore,
  required String shelterId,
  required Animal animal,
}) async {
  await firestore
      .collection('shelters')
      .doc(shelterId)
      .collection('${animal.species}s')
      .doc(animal.id)
      .set(animal.toMap());
}
