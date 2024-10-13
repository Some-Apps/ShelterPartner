import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;


class DeviceSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch account details for a specific user ID
  Stream<DocumentSnapshot> fetchUserDetails(String userID) {
    return _firestore.collection('users').doc(userID).snapshots();
  }

Future<void> toggleDeviceSetting(String userID, String field) async {
  final docRef = _firestore.collection('users').doc(userID);
  final snapshot = await docRef.get();

  // Check if document exists
  if (!snapshot.exists) {
    throw Exception("Document does not exist");
  }

  // Start at the 'deviceSettings' part of the document
  dynamic currentValue = snapshot.data()?['deviceSettings'];

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
      'deviceSettings.${fieldParts.join('.')}': !currentValue[lastField],  // Toggle the boolean value
    }).catchError((error) {
      throw Exception("Failed to toggle: $error");
    });
  } else {
    throw Exception("Field is not a boolean or doesn't exist");
  }
}


  // Method to modify a specific string attribute within volunteerSettings
  Future<void> modifyDeviceSettingString(String userID, String field, String newValue) async {
    final docRef = _firestore.collection('users').doc(userID);
    return docRef.update({
      'deviceSettings.$field': newValue,  // Update the string value
    }).catchError((error) {
      throw Exception("Failed to modify: $error");
    });
  }



  Future<void> incrementDeviceSetting(String userID, String field) async {
    final docRef = _firestore.collection('users').doc(userID);
    return docRef.update({
      'deviceSettings.$field': FieldValue.increment(1),
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
    });
  }

  Future<void> decrementDeviceSetting(String userID, String field) async {
    final docRef = _firestore.collection('users').doc(userID);
    return docRef.update({
      'deviceSettings.$field': FieldValue.increment(-1),
    }).catchError((error) {
      throw Exception("Failed to decrement: $error");
    });
  }
}

final deviceSettingsRepositoryProvider = Provider<DeviceSettingsRepository>((ref) {
  return DeviceSettingsRepository();
});
