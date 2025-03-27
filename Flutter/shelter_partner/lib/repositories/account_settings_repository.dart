import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch account details for a specific user ID
  Stream<DocumentSnapshot> fetchUserDetails(String userID) {
    return _firestore.collection('users').doc(userID).snapshots();
  }

Future<void> toggleAccountSetting(String userID, String field) async {
  final docRef = _firestore.collection('users').doc(userID);
  final snapshot = await docRef.get();

  // Check if document exists
  if (!snapshot.exists) {
    throw Exception("Document does not exist");
  }

  // Get the 'accountSettings' map (or initialize it if it doesn't exist)
  Map<String, dynamic> accountSettings =
      (snapshot.data()?['accountSettings'] as Map<String, dynamic>?) ?? {};

  // Split the field into parts (e.g., "geofence.isEnabled" becomes ["geofence", "isEnabled"])
  final fieldParts = field.split('.');

  // Traverse (or create) the nested structure for the field
  dynamic currentValue = accountSettings;
  for (int i = 0; i < fieldParts.length - 1; i++) {
    if (currentValue[fieldParts[i]] is Map<String, dynamic>) {
      currentValue = currentValue[fieldParts[i]];
    } else {
      // If the nested map doesn't exist, initialize it
      currentValue[fieldParts[i]] = <String, dynamic>{};
      currentValue = currentValue[fieldParts[i]];
    }
  }

  // The last part is the specific field to toggle (e.g., "simplisticMode")
  final lastField = fieldParts.last;

  // If the field is missing or not a bool, assume default value of true
  bool currentBool = true;
  if (currentValue[lastField] is bool) {
    currentBool = currentValue[lastField] as bool;
  }
  final newValue = !currentBool;

  // Update the nested field using the dot notation in the field path
  return docRef.update({
    'accountSettings.${fieldParts.join('.')}': newValue,
  }).catchError((error) {
    throw Exception("Failed to toggle: $error");
  });
}

  // Method to modify a specific string attribute within volunteerSettings
  Future<void> modifyAccountSettingString(
      String userID, String field, String newValue) async {
    final docRef = _firestore.collection('users').doc(userID);
    return docRef.update({
      'accountSettings.$field': newValue, // Update the string value
    }).catchError((error) {
      throw Exception("Failed to modify: $error");
    });
  }

  Future<void> incrementAccountSetting(String userID, String field) async {
    final docRef = _firestore.collection('users').doc(userID);
    return docRef.update({
      'accountSettings.$field': FieldValue.increment(1),
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
    });
  }

  Future<void> decrementAccountSetting(String userID, String field) async {
    final docRef = _firestore.collection('users').doc(userID);
    return docRef.update({
      'accountSettings.$field': FieldValue.increment(-1),
    }).catchError((error) {
      throw Exception("Failed to decrement: $error");
    });
  }


 Future<void> saveFilterExpression(String userID, Map<String, dynamic> filterExpression) async {
  final docRef = _firestore.collection('users').doc(userID);
  return docRef.update({
    'accountSettings.enrichmentFilter': filterExpression,
  }).catchError((error) {
    throw Exception("Failed to save filter expression: $error");
  });
}




Future<Map<String, dynamic>?> loadFilterExpression(String userID) async {
  final docRef = _firestore.collection('users').doc(userID);
  final snapshot = await docRef.get();
  if (snapshot.exists) {
    final data = snapshot.data();
    if (data != null && data['accountSettings'] != null && data['accountSettings']['enrichmentFilter'] != null) {
      return Map<String, dynamic>.from(data['accountSettings']['enrichmentFilter']);
    }
  }
  return null;
}


}

final accountSettingsRepositoryProvider =
    Provider<AccountSettingsRepository>((ref) {
  return AccountSettingsRepository();
});
