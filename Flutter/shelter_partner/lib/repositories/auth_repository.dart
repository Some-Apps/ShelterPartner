import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/device_settings.dart';
import 'package:shelter_partner/models/geofence.dart';
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/models/shelter_settings.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/models/volunteer_settings.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  AuthRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

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

 Future<void> deleteAccount(String email, String password) async {
  final user = _firebaseAuth.currentUser;
  if (user != null) {
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password, 
    );

    try {
      await user.reauthenticateWithCredential(credential);

      // Fetch the shelter ID linked to the user
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final shelterId = userDoc.data()?['shelterID'];

      if (shelterId != null) {
        // Manually delete documents from known subcollections
        final subcollections = ['cats', 'dogs']; // replace with actual subcollection names

        for (var subcollectionName in subcollections) {
          final snapshots = await _firestore.collection('shelters').doc(shelterId).collection(subcollectionName).get();
          for (var doc in snapshots.docs) {
            await doc.reference.delete();
          }
        }

        // Delete the shelter document from Firestore
        await _firestore.collection('shelters').doc(shelterId).delete();
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user from Firebase Auth
      await user.delete();

    } catch (e) {
      print('Error reauthenticating user: $e');
    }
  }
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
    // Create default device settings for the user
    final defaultDeviceSettings = DeviceSettings(
      adminMode: true,
      photoUploadsAllowed: true,
      mainSort: 'Last Let Out',
      visitorSort: 'Alphabetical',
      allowBulkTakeOut: true,
      minimumLogMinutes: 10,
      automaticallyPutBackAnimals: true,
      ignoreVisitWhenAutomaticallyPutBack: false,
      automaticPutBackHours: 12,
      requireLetOutType: true,
      requireEarlyPutBackReason: true,
      requireName: true,
      createLogsWhenUnderMinimumDuration: false,
      showNoteDates: true,
      showLogs: true,
      showAllAnimals: true,
      showCustomForm: false,
      customFormURL: "https://example.com",
      buttonType: 'In App',
      appendAnimalDataToURL: false,
    );

    // Create user document with device settings
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'shelterID': shelterId,
      'type': 'admin',
      'deviceSettings': defaultDeviceSettings.toMap(),
    });

    // Create the shelter without deviceSettings
    await createShelterWithPlaceholder(
      shelterId: shelterId,
      shelterName: shelterName.trim(),
      shelterAddress: shelterAddress.trim(),
      selectedManagementSoftware: selectedManagementSoftware.trim(),
      // Add cats and dogs from CSV files
    );
  }

  Future<void> createShelterWithPlaceholder({
    required String shelterId,
    required String shelterName,
    required String shelterAddress,
    required String selectedManagementSoftware,
  }) async {
    final shelterData = Shelter(
      id: shelterId,
      name: shelterName,
      address: shelterAddress,
      createdAt: Timestamp.now(),
      managementSoftware: selectedManagementSoftware,
      shelterSettings: ShelterSettings(
        scheduledReports: [],
        catTags: ['Calm', 'Playful', 'Independent'], // Example placeholder tags
        dogTags: ['Friendly', 'Energetic', 'Loyal'],
        earlyPutBackReasons: ['Sick', 'Behavioral'],
        letOutTypes: ['Playtime', 'Exercise'],
        apiKeys: [],
        requestCount: 0,
        requestLimit: 1000,
      ),
      volunteerSettings: VolunteerSettings(
        photoUploadsAllowed: true,
        mainSort: 'Last Let Out',
        allowBulkTakeOut: false,
        minimumLogMinutes: 5,
        automaticallyPutBackAnimals: true,
        ignoreVisitWhenAutomaticallyPutBack: true,
        automaticPutBackHours: 24,
        requireLetOutType: true,
        requireEarlyPutBackReason: false,
        requireName: true,
        createLogsWhenUnderMinimumDuration: false,
        showNoteDates: false,
        showLogs: true,
        showAllAnimals: true,
        showCustomForm: false,
        customFormURL: "",
        appendAnimalDataToURL: true,
        // Create default geofence
        geofence: Geofence(
          location: const GeoPoint(43.0722, -89.4008),
          radius: 500,
          zoom: 15,
          isEnabled: false,
        ),
      ),
      volunteers: List<Volunteer>.empty(),
    );

    // Upload the shelter data to Firestore without deviceSettings
    await _firestore.collection('shelters').doc(shelterId).set({
      'name': shelterData.name,
      'address': shelterData.address,
      'createdAt': shelterData.createdAt,
      'managementSoftware': shelterData.managementSoftware,
      'shelterSettings': shelterData.shelterSettings.toMap(),
      'volunteerSettings': shelterData.volunteerSettings.toMap(),
    });

    print('Shelter data uploaded for: $shelterName');

    // After creating shelter, upload cats and dogs from CSV or placeholders
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
        final animalId = row['id'].toString();

        final data = {
          'alert': row['alert'] ?? '',
          'species': collectionName == 'dogs'
              ? 'dog'
              : collectionName == 'cats'
                  ? 'cat'
                  : 'Unknown',
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
          'inKennel': true,
          'location': row['location'] ?? '',
          'name': row['name'] ??
              'Unknown', // Default to 'Unknown' if name is missing
          'startTime':
              FieldValue.serverTimestamp(), // Add timestamps for Firestore
          'created': FieldValue.serverTimestamp(),
          'intakeDate': FieldValue.serverTimestamp(),
          'photos': [
            {
              'id': const Uuid().v4(),
              'url':
                  "https://storage.googleapis.com/development-e5282.appspot.com/${collectionName == 'dogs' ? 'Dogs' : 'Cats'}/$animalId.jpeg",
              'timestamp': Timestamp.now(),
            }
          ], // Example placeholder for photos
          'notes': [
            {
              'id': const Uuid().v4(),
              'note': 'Example note 1',
              'author': 'Person 1',
              'timestamp': Timestamp.now(),
            },
            {
              'id': const Uuid().v4(),
              'note': 'Example note 2',
              'author': 'Person 2',
              'timestamp': Timestamp.now(),
            },
            {
              'id': const Uuid().v4(),
              'note': 'Example note 3',
              'author': 'Person 3',
              'timestamp': Timestamp.now(),
            },
            {
              'id': const Uuid().v4(),
              'note': 'Example note 4',
              'author': 'Person 1',
              'timestamp': Timestamp.now(),
            },
            {
              'id': const Uuid().v4(),
              'note': 'Example note 5',
              'author': 'Person 2',
              'timestamp': Timestamp.now(),
            }
          ], // Example placeholder for notes
          'logs': [
            {
              'id': const Uuid().v4(),
              'type': 'Let Out',
              'author': 'Admin',
              'startTime': Timestamp.now(),
              'endTime': Timestamp.now(),
            },
            {
              'id': const Uuid().v4(),
              'type': 'Let Out',
              'author': 'Admin',
              'startTime': Timestamp.now(),
              'endTime': Timestamp.now(),
            },
            {
              'id': const Uuid().v4(),
              'type': 'Let Out',
              'author': 'Admin',
              'startTime': Timestamp.now(),
              'endTime': Timestamp.now(),
            }
          ], // Example placeholder for logs
          'sex': getRandomSex(),
          'age': "2 years 3 months",
          'breed': "Example Retriever",
            'description': "This is an example animal description. This animal is known for its friendly demeanor and playful nature. It enjoys spending time with people and other animals. It has a calm temperament and is very affectionate. This animal is also very intelligent and quick to learn new tricks. It loves to play fetch and enjoys long walks in the park. It is well-behaved and responds well to commands. This animal is looking for a loving home where it can receive plenty of attention and care. It is in good health and has been vaccinated. This animal would make a great addition to any family.",
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
      print(
          'Raw CSV string: $csvString'); // Debugging: print the entire raw string

      // Parse the CSV string
      final List<List<dynamic>> csvRows =
          const CsvToListConverter(eol: '\n').convert(csvString);
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

  String getRandomSex() {
    const sexes = ["Male", "Female"];
    return sexes[Random().nextInt(sexes.length)];
  }

  String getRandomBehaviorGroup() {
    const behaviors = ['Behavior 1', 'Behavior 2', 'Behavior 3', 'Behavior 4'];
    return behaviors[Random().nextInt(behaviors.length)];
  }

  int getRandomIndex(int max) {
    return Random().nextInt(max);
  }
}
