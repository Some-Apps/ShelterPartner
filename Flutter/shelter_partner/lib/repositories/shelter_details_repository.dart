import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShelterDetailsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch account details for a specific shelter ID
  Stream<DocumentSnapshot> fetchShelterDetails(String shelterID) {
    return _firestore.collection('shelters').doc(shelterID).snapshots();
  }
}

final shelterDetailsRepositoryProvider =
    Provider<ShelterDetailsRepository>((ref) {
  return ShelterDetailsRepository();
});
