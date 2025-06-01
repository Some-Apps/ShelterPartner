import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class StatsRepository {
  final FirebaseFirestore _firestore;
  StatsRepository({required FirebaseFirestore firestore})
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

  /// Fetches the last API sync time and related data
  Stream<Map<String, dynamic>> fetchLastSyncData(String shelterID) {
    return _firestore.collection('shelters').doc(shelterID).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return {};
      return snapshot.data() ?? {};
    });
  }

  /// Fetches only the last email sync timestamp
  Stream<String> fetchLastEmailSync(String shelterID) {
    return _firestore.collection('shelters').doc(shelterID).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return "No email sync data available";

      final data = snapshot.data();
      Timestamp? lastEmailSyncTimestamp = data?['lastEmailSync'];

      if (lastEmailSyncTimestamp != null) {
        return lastEmailSyncTimestamp.toDate().toLocal().toString();
      } else {
        return "No email sync data available";
      }
    });
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return StatsRepository(firestore: firestore);
});
