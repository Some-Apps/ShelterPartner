import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class VolunteersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch account details for a specific shelter ID
  Stream<DocumentSnapshot> fetchShelterDetails(String shelterID) {
    return _firestore.collection('shelters').doc(shelterID).snapshots();
  }

  // Method to toggle a specific field within volunteerSettings attribute
  Future<void> toggleVolunteerSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    final snapshot = await docRef.get();
    final currentValue = snapshot['volunteerSettings'][field] as bool;
    return docRef.update({
      'volunteerSettings.$field': !currentValue,  // Toggle the boolean value
    }).catchError((error) {
      throw Exception("Failed to toggle: $error");
    });
  }

  // Method to modify a specific string attribute within volunteerSettings
  Future<void> modifyVolunteerSettingString(String shelterID, String field, String newValue) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.$field': newValue,  // Update the string value
    }).catchError((error) {
      throw Exception("Failed to modify: $error");
    });
  }

  // Method to increment a specific field within volunteerSettings attribute
  Future<void> incrementVolunteerSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.$field': FieldValue.increment(1),  // Access nested volunteerSettings field
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
    });
  }

  // Method to decrement a specific field within volunteerSettings attribute
  Future<void> decrementVolunteerSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.$field': FieldValue.increment(-1),  // Access nested volunteerSettings field
    }).catchError((error) {
      throw Exception("Failed to decrement: $error");
    });
  }
}

// Provider to access the VolunteersRepository
final volunteersRepositoryProvider = Provider<VolunteersRepository>((ref) {
  return VolunteersRepository();
});