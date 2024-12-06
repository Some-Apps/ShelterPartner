import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qonversion_flutter/qonversion_flutter.dart';
import 'package:shelter_partner/models/account_settings.dart';
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
      Qonversion.getSharedInstance().setUserProperty(
          QUserPropertyKey.customUserId, AppUser.fromDocument(doc).id);
      print("User ID: ${AppUser.fromDocument(doc).id}");
      try {
        final userInfo = await Qonversion.getSharedInstance()
            .identify(AppUser.fromDocument(doc).id);
        // use userInfo if necessary
      } catch (e) {
        // handle error here
      }
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
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final shelterId = userDoc.data()?['shelterID'];

        if (shelterId != null) {
          // Manually delete documents from known subcollections
          final subcollections = [
            'cats',
            'dogs'
          ]; // replace with actual subcollection names

          for (var subcollectionName in subcollections) {
            final snapshots = await _firestore
                .collection('shelters')
                .doc(shelterId)
                .collection(subcollectionName)
                .get();
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
    // Create default account settings for the user
    final defaultAccountSettings = AccountSettings(
      photoUploadsAllowed: true,
      enrichmentSort: 'Last Let Out',
      enrichmentFilter: null,
      visitorFilter: null,
      visitorSort: 'Alphabetical',
      slideshowSize: "Scaled to Fit",
      mode: 'Admin',
      allowBulkTakeOut: true,
      minimumLogMinutes: 10,
      slideshowTimer: 15,
      requireLetOutType: false,
      requireEarlyPutBackReason: false,
      requireName: false,
      createLogsWhenUnderMinimumDuration: false,
      showCustomForm: false,
      customFormURL: "https://example.com",
      buttonType: 'In App',
      appendAnimalDataToURL: false,
      removeAds: true,

      simplisticMode: true,
    );

    // Create user document with account settings
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),

      'lastActivity': Timestamp.now(),
      'averageLogDuration': 0,
      'totalTimeLoggedWithAnimals': 0,

      'shelterID': shelterId,
      'type': 'admin',
      'accountSettings': defaultAccountSettings.toMap(),
      'removeAds': true
    });

    // Create the shelter without accountSettings
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
        apiKey: '',
        asmUsername: '',
        asmPassword: '',
        asmAccountNumber: '',
        requestCount: 0,
        requestLimit: 1000,
        automaticallyPutBackAnimals: false,
        ignoreVisitWhenAutomaticallyPutBack: false,
        automaticPutBackHours: 12,
      ),
      volunteerSettings: VolunteerSettings(
        photoUploadsAllowed: true,
        enrichmentSort: 'Last Let Out',
        enrichmentFilter: null,
        allowBulkTakeOut: false,
        minimumLogMinutes: 5,
        requireLetOutType: false,
        requireEarlyPutBackReason: false,
        requireName: false,
        createLogsWhenUnderMinimumDuration: false,
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

    // Upload the shelter data to Firestore without accountSettings
    await _firestore.collection('shelters').doc(shelterId).set({
      'name': shelterData.name,
      'address': shelterData.address,
      'createdAt': shelterData.createdAt,
      'managementSoftware': shelterData.managementSoftware,
      'shelterSettings': shelterData.shelterSettings.toMap(),
      'volunteerSettings': shelterData.volunteerSettings.toMap(),
      'volunteers': [],
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

      // Create a batch to perform multiple writes as a single atomic operation
      WriteBatch batch = _firestore.batch();

      // Iterate over the loaded CSV data and add each row to the batch
      for (final row in csvData) {
        final animalId = row['id'].toString();

        final data = {
          'takeOutAlert': ['', '', '', '', 'This is some sort of example alert']
              .randomElement(),
          'putBackAlert': ['', '', '', '', 'This is some sort of example alert']
              .randomElement(),

          'species': collectionName == 'dogs'
              ? 'dog'
              : collectionName == 'cats'
                  ? 'cat'
                  : 'Unknown',
          'symbolColor': [
            'red',
            'green',
            'blue',
            'yellow',
            'orange',
            'purple'
          ].randomElement(),
          'symbol': 'pets', // Example static value, adjust as needed
          'volunteerCategory': ['Red', 'Green', 'Blue'].randomElement(),
          'locationCategory':
              ['Building 1', 'Building 2', 'Building 3'].randomElement(),
          'behaviorCategory': [
            'Behavior 1',
            'Behavior 2',
            'Behavior 3',
            'Behavior 4'
          ].randomElement(),
          'medicalCategory':
              ['Medical 1', 'Medical 2', 'Medical 3'].randomElement(),
          'adoptionCategory':
              ['Adoption 1', 'Adoption 2', 'Adoption 3'].randomElement(),
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
          'tags': [
            {
              'id': const Uuid().v4(),
              'title': 'Friendly',
              'count': 1,
              'timestamp': Timestamp.now(),
            }
          ], // Example placeholder for tags
          'sex': ['m', 'f'].randomElement(),
          'monthsOld': [2, 6, 12, 24, 36].randomElement(),
          'breed': ['some breed', 'another breed'].randomElement(),
          'description': [
            'This animal is very friendly and loves to play with toys. He enjoys long walks and is very good with children. He has a calm temperament and is very affectionate.',
            'This animal is energetic and loves to run around. She is very playful and enjoys playing fetch. She is very loyal and protective of her family.',
            'This animal is very independent and likes to explore his surroundings. He is curious and intelligent, and enjoys solving puzzles and playing with interactive toys.',
            'This animal is very gentle and loves to cuddle. She is very affectionate and enjoys being around people. She has a calm demeanor and is very good with other animals.',
            'This animal is very playful and loves to be the center of attention. He enjoys playing with other animals and is very social. He has a lot of energy and loves to run and play.'
          ].randomElement(),
        };

        // Add the document to the batch
        final docRef = _firestore
            .collection('shelters/$shelterId/$collectionName')
            .doc(animalId);
        batch.set(docRef, data);
      }

      // Commit the batch
      await batch.commit();
      print('Successfully uploaded all documents for $collectionName');
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
}

extension RandomElement<T> on List<T> {
  T randomElement() {
    final random = Random();
    return this[random.nextInt(length)];
  }
}
