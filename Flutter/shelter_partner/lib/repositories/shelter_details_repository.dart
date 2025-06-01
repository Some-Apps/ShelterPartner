import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class ShelterDetailsRepository {
  final FirebaseFirestore _firestore;
  ShelterDetailsRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  // Method to fetch account details for a specific shelter ID
  Stream<DocumentSnapshot> fetchShelterDetails(String shelterID) {
    return _firestore.collection('shelters').doc(shelterID).snapshots();
  }
}

final shelterDetailsRepositoryProvider = Provider<ShelterDetailsRepository>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return ShelterDetailsRepository(firestore: firestore);
});
