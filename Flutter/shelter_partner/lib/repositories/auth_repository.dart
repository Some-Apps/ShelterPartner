import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Fetch user by ID
  Future<AppUser?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromDocument(doc);
    }
    return null;
  }

  // Sign in user with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  // Sign up a new user
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  // Get the current Firebase user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Sign out user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> createUserDocument({
    required String uid,
    required String firstName,
    required String lastName,
    required String shelterId,
    required String email,
    required String selectedManagementSoftware,
    required String shelterName,
    required String shelterAddress,
  }) async {
    // Create user document
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'shelter_id': shelterId,
      'type': 'admin',
    });

    // Create shelter document
    await _firestore.collection('shelters').doc(shelterId).set({
      'shelter_name': shelterName.trim(),
      'address': shelterAddress.trim(),
      'management_software': selectedManagementSoftware,
      'createdAt': FieldValue.serverTimestamp(),
      'reportsDay': 'Never',
      'reportsEmail': '',
      'groupOptions': ["Color", "Building", "Behavior"],
      'secondarySortOptions': ["Color", "Building", "Behavior"],
    });

    // Add cats and dogs from CSV files
    await addAnimalsFromCSV(shelterId);
  }

  Future<void> addAnimalsFromCSV(String shelterId) async {
    final animalTypes = ['cats', 'dogs'];

    for (var animalType in animalTypes) {
      print('Attempting to upload $animalType for shelter $shelterId...');
      await uploadDataToFirestore(
        filename: 'assets/csv/$animalType.csv', // Corrected path
        collectionName: animalType,
        shelterId: shelterId,
      );
    }
  }

  Future<void> uploadDataToFirestore({
    required String filename,
    required String collectionName,
    required String shelterId,
  }) async {
    try {
      // Load CSV data using the loadCsvData function
      print('Loading CSV file: $filename');
      final csvData =
          await loadCsvData(filename); // Load CSV data from the file

      if (csvData.isEmpty) {
        print('No data found in CSV file: $filename');
        return; // Exit if no data is found
      } else {
        print('Loaded ${csvData.length} rows from $filename');
      }

      // Iterate over the loaded CSV data and upload each row to Firestore
      for (final row in csvData) {
        final animalId = row['id'].toString(); // Assuming 'id' is a column in your CSV
        if (animalId == null) {
          print('Skipping row without an ID');
          continue; // Skip rows that do not have an ID
        }

        final data = {
          'alert': row['alert'] ?? '',
          'canPlay': (row['canPlay'] ?? '').toLowerCase() ==
              'true', // Ensure boolean conversion
          'symbolColor': getRandomColor(),
          'symbol': 'pawprint.fill', // Example static value, adjust as needed
          'colorGroup': getRandomColorGroup(),
          'buildingGroup': getRandomBuildingGroup(),
          'behaviorGroup': getRandomBehaviorGroup(),
          'colorSort': getRandomIndex(7),
          'buildingSort': getRandomIndex(3),
          'behaviorSort': getRandomIndex(4),
          'id': animalId,
          'inKennel': (row['inKennel'] ?? '').toLowerCase() ==
              'true', // Ensure boolean conversion
          'location': row['location'] ?? '',
          'name': row['name'] ??
              'Unknown', // Default to 'Unknown' if name is missing
          'startTime':
              FieldValue.serverTimestamp(), // Add timestamps for Firestore
          'created': FieldValue.serverTimestamp(),
          'photos': [], // Example placeholder for photos
          'sex': row['sex'] ?? 'Unknown',
          'age': row['age'] ?? 'Unknown',
          'breed': row['breed'] ?? 'Unknown',
          'description': row['description'] ?? 'No description available.',
        };

        // Upload the document to Firestore
        print(
            'Uploading document for $collectionName: ${row['name']} (ID: $animalId)');
        await _firestore
            .collection('shelters/$shelterId/$collectionName')
            .doc(animalId)
            .set(data);
        print('Successfully uploaded $collectionName document for $animalId');
      }
    } catch (e) {
      print('Error uploading data from $filename: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadCsvData(String filename) async {
  print('Attempting to load CSV data from $filename');
  try {
    // Load CSV file as a string
    final csvString = await rootBundle.loadString(filename);
    print('Raw CSV string: $csvString'); // Debugging: print the entire raw string

    // Parse the CSV string
    final List<List<dynamic>> csvRows = const CsvToListConverter(eol: '\n').convert(csvString);
    print('Parsed CSV rows: $csvRows'); // Debugging: print parsed rows

    if (csvRows.isEmpty) {
      print('No data found in CSV file: $filename');
      return [];
    }

    // Assuming the first row is the header (column names)
    final headers = csvRows.first.map((header) => header.toString()).toList();
    print('CSV Headers: $headers');

    final List<Map<String, dynamic>> csvData = [];
    for (int i = 1; i < csvRows.length; i++) {
      print('Processing row $i: ${csvRows[i]}');
      final Map<String, dynamic> rowMap = {};
      for (int j = 0; j < headers.length; j++) {
        rowMap[headers[j]] = csvRows[i][j];
      }
      csvData.add(rowMap);
    }

    print('Successfully loaded ${csvData.length} rows from $filename');
    return csvData;
  } catch (e) {
    print('Error loading CSV data from $filename: $e');
    return [];
  }
}

  // Mock functions for random data generation (replace with your logic)
  String getRandomColor() {
    const colors = [
      'Red',
      'Blue',
      'Green',
      'Orange',
      'Pink',
      'Yellow',
      'Brown'
    ];
    return colors[Random().nextInt(colors.length)];
  }

  String getRandomColorGroup() {
    return getRandomColor();
  }

  String getRandomBuildingGroup() {
    const buildings = ['Building 1', 'Building 2', 'Building 3'];
    return buildings[Random().nextInt(buildings.length)];
  }

  String getRandomBehaviorGroup() {
    const behaviors = ['Behavior 1', 'Behavior 2', 'Behavior 3', 'Behavior 4'];
    return behaviors[Random().nextInt(behaviors.length)];
  }

  int getRandomIndex(int max) {
    return Random().nextInt(max);
  }
}
