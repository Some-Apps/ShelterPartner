import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShelterSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch account details for a specific shelter ID
  Stream<DocumentSnapshot> fetchShelterDetails(String shelterID) {
    return _firestore.collection('shelters').doc(shelterID).snapshots();
  }

  // Method to add a string to an array within shelterSettings attribute
  Future<void> addStringToShelterSettingsArray(
      String shelterID, String field, String value) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field':
          FieldValue.arrayUnion([value]), // Add the string to the array
    }).catchError((error) {
      throw Exception("Failed to add string to array: $error");
    });
  }

  // Method to modify a specific string attribute within volunteerSettings
  Future<void> modifyDeviceSettingString(
      String shelterID, String field, String newValue) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'deviceSettings.$field': newValue, // Update the string value
    }).catchError((error) {
      throw Exception("Failed to modify: $error");
    });
  }

  // Method to add a map to an array within shelterSettings attribute
  Future<void> addMapToShelterSettingsArray(
      String shelterID, String field, Map<String, dynamic> value) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field':
          FieldValue.arrayUnion([value]), // Add the map to the array
    }).catchError((error) {
      throw Exception("Failed to add map to array: $error");
    });
  }

  Future<void> removeMapFromShelterSettingsArray(
      String shelterID, String field, Map<String, dynamic> value) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field': FieldValue.arrayRemove([value]),
    }).catchError((error) {
      throw Exception("Failed to remove map from array: $error");
    });
  }

  // Method to remove a string from an array within shelterSettings attribute
  Future<void> removeStringFromShelterSettingsArray(
      String shelterID, String field, String value) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field':
          FieldValue.arrayRemove([value]), // Remove the string from the array
    }).catchError((error) {
      throw Exception("Failed to remove string from array: $error");
    });
  }

  // Method to reorder items in an array of maps within shelterSettings attribute
  Future<void> reorderMapArrayInShelterSettings(String shelterID, String field,
      List<Map<String, dynamic>> newOrder) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field':
          newOrder, // Update the array of maps with the new order
    }).catchError((error) {
      throw Exception("Failed to reorder map array: $error");
    });
  }

  // Method to reorder items in an array within shelterSettings attribute
  Future<void> reorderShelterSettingsArray(
      String shelterID, String field, List<String> newOrder) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field': newOrder, // Update the array with the new order
    }).catchError((error) {
      throw Exception("Failed to reorder array: $error");
    });
  }

  // Method to toggle a specific field within shelterSettings attribute
  Future<void> toggleShelterSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    final snapshot = await docRef.get();

    // Check if document exists
    if (!snapshot.exists) {
      throw Exception("Document does not exist");
    }

    dynamic currentValue = snapshot.data()?['deviceSettings'];

    final fieldParts = field.split('.');

    for (int i = 0; i < fieldParts.length - 1; i++) {
      currentValue = currentValue?[fieldParts[i]];
    }

    final lastField = fieldParts.last;

    if (currentValue != null && currentValue[lastField] is bool) {
      return docRef.update({
        'deviceSettings.${fieldParts.join('.')}': !currentValue[lastField],
      }).catchError((error) {
        throw Exception("Failed to toggle: $error");
      });
    } else {
      throw Exception("Field is not a boolean or doesn't exist");
    }
  }

  // Method to modify a specific string attribute within shelterSettings
  Future<void> modifyShelterSettingString(
      String shelterID, String field, String newValue) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field': newValue, // Update the string value
    }).catchError((error) {
      throw Exception("Failed to modify: $error");
    });
  }

  // Method to increment a specific field within shelterSettings attribute
  Future<void> incrementShelterSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field':
          FieldValue.increment(1), // Access nested shelterSettings field
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
    });
  }

  // Method to decrement a specific field within shelterSettings attribute
  Future<void> decrementShelterSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.$field':
          FieldValue.increment(-1), // Access nested shelterSettings field
    }).catchError((error) {
      throw Exception("Failed to decrement: $error");
    });
  }

  // Method to increment a specific field within volunteerSettings attribute
  Future<void> incrementDeviceSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'deviceSettings.$field':
          FieldValue.increment(1), // Access nested volunteerSettings field
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
    });
  }

  // Method to decrement a specific field within volunteerSettings attribute
  Future<void> decrementDeviceSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'deviceSettings.$field':
          FieldValue.increment(-1), // Access nested volunteerSettings field
    }).catchError((error) {
      throw Exception("Failed to decrement: $error");
    });
  }
}

// Provider to access the ShelterSettingsRepository
final shelterSettingsRepositoryProvider =
    Provider<ShelterSettingsRepository>((ref) {
  return ShelterSettingsRepository();
});
