import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class VisitorsRepository {
  final FirebaseFirestore _firestore;
  VisitorsRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Stream<List<Animal>> fetchAnimals(String shelterID) {
    final catsStream = _firestore
        .collection('shelters/$shelterID/cats')
        .snapshots();
    final dogsStream = _firestore
        .collection('shelters/$shelterID/dogs')
        .snapshots();

    return CombineLatestStream.list([catsStream, dogsStream]).map((snapshots) {
      final allAnimals = <Animal>[];
      for (var snapshot in snapshots) {
        allAnimals.addAll(
          snapshot.docs.map((doc) => Animal.fromFirestore(doc.data(), doc.id)),
        );
      }
      return allAnimals;
    });
  }
}

final visitorsRepositoryProvider = Provider<VisitorsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return VisitorsRepository(firestore: firestore);
});
