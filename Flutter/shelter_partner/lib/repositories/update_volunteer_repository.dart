import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdateVolunteerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  Stream<DocumentSnapshot> fetchShelterDetails(String shelterID) {
    return _firestore.collection('shelters').doc(shelterID).snapshots();
  }
  // Method to modify a specific string attribute within shelterSettings
  Future<void> modifyVolunteerLastActivity(
      String shelterID, String volunteerId, String field, Timestamp newValue) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteers.$volunteerId.$field': newValue,
    }).catchError((error) {
      throw Exception("Failed to modify: $error");
    });
  }
}

// Provider for AddNoteRepository
final updateVolunteerRepositoryProvider = Provider<UpdateVolunteerRepository>((ref) {
  return UpdateVolunteerRepository();
});
