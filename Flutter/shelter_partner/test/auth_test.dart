// test/auth_firestore_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'auth_test.mocks.dart';

@GenerateMocks([FirebaseAuth, UserCredential, firebase_auth.User])
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late FakeFirebaseFirestore firestore;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    firestore = FakeFirebaseFirestore(); 
  });

  group('Firebase Auth Tests', () {
    test('Create Shelter Account', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'shelter@example.com',
        password: 'shelter123',
      )).thenAnswer((_) async => mockUserCredential);

      final result = await mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'shelter@example.com',
        password: 'shelter123',
      );

      expect(result, mockUserCredential);
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'shelter@example.com',
        password: 'shelter123',
      )).called(1); 
    });

    test('Create Volunteer Account', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'volunteer@example.com',
        password: 'volunteer123',
      )).thenAnswer((_) async => mockUserCredential);

      final result = await mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'volunteer@example.com',
        password: 'volunteer123',
      );

      expect(result, mockUserCredential);
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'volunteer@example.com',
        password: 'volunteer123',
      )).called(1);
    });

    test('Change Password', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.updatePassword('newPassword123')).thenAnswer((_) async => null);

      await mockFirebaseAuth.currentUser!.updatePassword('newPassword123');

      verify(mockUser.updatePassword('newPassword123')).called(1);
    });

    test('Logout', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => null);

      await mockFirebaseAuth.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
    });
  });

  group('Firestore Notes and Tags', () {
    test('Add note', () async {
      await firestore.collection('notes').add({
        'title': 'Note 1',
        'content': 'This is a note',
      });
      final snapshot = await firestore.collection('notes').get();
      expect(snapshot.docs.length, 1);
    });

    test('Delete note', () async {
      final doc = await firestore.collection('notes').add({
        'title': 'Note to delete',
      });
      await firestore.collection('notes').doc(doc.id).delete();
      final snapshot = await firestore.collection('notes').get();
      expect(snapshot.docs.length, 0);
    });

    test('Add tag', () async {
      await firestore.collection('tags').add({
        'name': 'Urgent',
      });
      final snapshot = await firestore.collection('tags').get();
      expect(snapshot.docs.first['name'], 'Urgent');
    });

    test('Delete tag', () async {
      final tagDoc = await firestore.collection('tags').add({
        'name': 'Optional',
      });
      await firestore.collection('tags').doc(tagDoc.id).delete();
      final snapshot = await firestore.collection('tags').get();
      expect(snapshot.docs.length, 0);
    });
  });


  group('Image Tests', () {
    test('Upload image to Firestore', () async {
      await firestore.collection('images').add({
        'url': 'https://example.com/image1.jpg',
        'uploadedAt': DateTime.now(),
      });

      final snapshot = await firestore.collection('images').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['url'], 'https://example.com/image1.jpg');
    });

    test('Display image (simulate image URL read)', () async {
      await firestore.collection('images').add({
        'url': 'https://example.com/image2.jpg',
        'uploadedAt': DateTime.now(),
      });

      final snapshot = await firestore.collection('images').get();

      for (final doc in snapshot.docs) {
        final url = doc['url'];
        expect(url, isNotNull);
        expect(Uri.tryParse(url)?.isAbsolute, isTrue); // Simulates valid image display
      }
    });
  });
test('Login with vedantvijay!@icloud.com  klausEUGENE@62', () async {
  // Mock the sign-in process
  when(mockFirebaseAuth.signInWithEmailAndPassword(
    email: 'vedantvijay!@icloud.com',
    password: 'klausEUGENE@62',
  )).thenAnswer((_) async => mockUserCredential);

  // Perform the login
  final result = await mockFirebaseAuth.signInWithEmailAndPassword(
    email: 'vedantvijay!@icloud.com',
    password: 'klausEUGENE@62',
  );

  // Check if the result matches the mocked user credential
  expect(result, mockUserCredential);

  // Verify if the signInWithEmailAndPassword method was called exactly once
  verify(mockFirebaseAuth.signInWithEmailAndPassword(
    email: 'vedantvijay!@icloud.com',
    password: 'klausEUGENE@62',
  )).called(1);
});
}