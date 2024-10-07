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

  // Check if document exists
  if (!snapshot.exists) {
    throw Exception("Document does not exist");
  }

  // Start at the 'volunteerSettings' part of the document
  dynamic currentValue = snapshot.data()?['volunteerSettings'];

  // Split the field into parts (e.g., "geofence.isEnabled" becomes ["geofence", "isEnabled"])
  final fieldParts = field.split('.');

  // Traverse to the correct nested field
  for (int i = 0; i < fieldParts.length - 1; i++) {
    currentValue = currentValue?[fieldParts[i]];
  }

  // The last part is the specific field to toggle (e.g., "isEnabled")
  final lastField = fieldParts.last;

  // Ensure the currentValue exists and is a boolean before toggling
  if (currentValue != null && currentValue[lastField] is bool) {
    return docRef.update({
      'volunteerSettings.${fieldParts.join('.')}': !currentValue[lastField],  // Toggle the boolean value
    }).catchError((error) {
      throw Exception("Failed to toggle: $error");
    });
  } else {
    throw Exception("Field is not a boolean or doesn't exist");
  }
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
  Future<void> changeGeofence(String shelterID, GeoPoint locaiton, double radius, double zoom) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.geofence.location': locaiton,
      'volunteerSettings.geofence.radius': radius,
      'volunteerSettings.geofence.zoom': zoom,
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
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
