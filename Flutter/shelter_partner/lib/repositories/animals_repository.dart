import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

class AnimalsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DocumentSnapshot>> fetchAnimals(String shelterID) {
    final catsStream = _firestore.collection('shelters/$shelterID/cats').snapshots();
    final dogsStream = _firestore.collection('shelters/$shelterID/dogs').snapshots();

    return CombineLatestStream.list([catsStream, dogsStream]).map((snapshots) {
      final allDocuments = <DocumentSnapshot>[];
      for (var snapshot in snapshots) {
        allDocuments.addAll(snapshot.docs);
      }
      return allDocuments;
    });
  }
}

final animalsRepositoryProvider = Provider<AnimalsRepository>((ref) {
  return AnimalsRepository();
});