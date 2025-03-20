import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/models/volunteer.dart';

class VolunteersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Shelter> fetchShelterWithVolunteers(String shelterID) {
    final shelterDocRef = _firestore.collection('shelters').doc(shelterID);
    final shelterStream = shelterDocRef.snapshots();

    return shelterStream.switchMap((shelterSnapshot) {
      if (!shelterSnapshot.exists) {
        return Stream.error('No shelter found');
      }

      Shelter shelter = Shelter.fromDocument(shelterSnapshot);

      // Fetch volunteers using shelterId
      final volunteersStream = _firestore
          .collection('users')
          .where('shelterID', isEqualTo: shelterID)
          .snapshots()
          .map((querySnapshot) {
            print('Volunteers: ${querySnapshot.docs.length}');
        return querySnapshot.docs
            .map((doc) => Volunteer.fromDocument(doc))
            .toList();
      });

      // Combine the shelter and volunteers
      return volunteersStream.map((volunteers) {
        shelter.volunteers = volunteers;
        return shelter;
      });
    });
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
        'volunteerSettings.${fieldParts.join('.')}':
            !currentValue[lastField], // Toggle the boolean value
      }).catchError((error) {
        throw Exception("Failed to toggle: $error");
      });
    } else {
      throw Exception("Field is not a boolean or doesn't exist");
    }
  }

  // Method to modify a specific string attribute within volunteerSettings
  Future<void> modifyVolunteerSettingString(
      String shelterID, String field, String newValue) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.$field': newValue, // Update the string value
    }).catchError((error) {
      throw Exception("Failed to modify: $error");
    });
  }

  // Method to increment a specific field within volunteerSettings attribute
  Future<void> changeGeofence(
      String shelterID, GeoPoint locaiton, double radius, double zoom) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.geofence.location': locaiton,
      'volunteerSettings.geofence.radius': radius,
      'volunteerSettings.geofence.zoom': zoom,
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
    });
  }

  Future<void> sendVolunteerInvite(
      String firstName, String lastName, String email, String shelterID) async {
    // Generate a random password
    String password = _generateRandomPassword();

    // Prepare data to send to the Cloud Run Function
    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'shelterID': shelterID
    };

    try {
      // Get the Firebase ID token for authentication
      String? idToken = await getIdToken();

      // Log the request body and headers
      print('Sending request with data: $data');
      print('Authorization: Bearer $idToken');

      // Send the authenticated request to Cloud Run
      final response = await http.post(
        Uri.parse('https://invite-volunteer-222422545919.us-central1.run.app'),
        headers: {
          'Authorization': 'Bearer $idToken', // Pass the Firebase Auth ID token
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      // Log the response
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] != 'success') {
          print('Error from Cloud Function: ${result['message']}');
          throw Exception(result['message']);
        } else {
          print('Invite sent successfully to $email');
        }
      } else {
        // Log full response for debugging
        print('Request failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to send invite: ${response.body}');
      }
    } catch (e) {
      // Log error details
      print('Error occurred: $e');
      throw Exception('Failed to send invite: $e');
    }
  }

  Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get the ID token from the current authenticated user
      return await user.getIdToken();
    } else {
      throw Exception("User is not authenticated");
    }
  }

  Future<void> deleteVolunteer(String id, String shelterId) async {
    try {
      // Get Firebase ID token for authentication
      final user = FirebaseAuth.instance.currentUser;
      String? idToken = await user?.getIdToken();

      // Create the URL with query parameters for the DELETE request
      final url = Uri.parse(
        'https://delete-volunteer-222422545919.us-central1.run.app'
        '?id=$id&shelterID=$shelterId',
      );

      // Log the request details for debugging
      print('Request URL: $url');
      print('Authorization: Bearer $idToken');

      // Make the DELETE request with the token in the headers
      final response = await http.delete(
        url,
        headers: {
          'Authorization':
              'Bearer $idToken', // Send the Firebase ID token for authentication
          'Content-Type': 'application/json',
        },
      );

      // Log response status and body
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete volunteer: ${response.body}');
      }

      final result = jsonDecode(response.body);
      if (result['success'] == false) {
        throw Exception(result['message']);
      }

      print('Volunteer deleted successfully');
    } catch (e) {
      print('Error occurred: $e');
      throw Exception('Failed to delete volunteer: $e');
    }
  }

String _generateRandomPassword() {
  const length = 6;
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  final rand = Random.secure();
  return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
}

  // Method to increment a specific field within volunteerSettings attribute
  Future<void> incrementVolunteerSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.$field':
          FieldValue.increment(1), // Access nested volunteerSettings field
    }).catchError((error) {
      throw Exception("Failed to increment: $error");
    });
  }

  // Method to decrement a specific field within volunteerSettings attribute
  Future<void> decrementVolunteerSetting(String shelterID, String field) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'volunteerSettings.$field':
          FieldValue.increment(-1), // Access nested volunteerSettings field
    }).catchError((error) {
      throw Exception("Failed to decrement: $error");
    });
  }
}

// Provider to access the VolunteersRepository
final volunteersRepositoryProvider = Provider<VolunteersRepository>((ref) {
  return VolunteersRepository();
});
