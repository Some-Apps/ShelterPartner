import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

/// Test helper class that provides overrides for Firebase providers
class FirebaseTestOverrides {
  static late FakeFirebaseFirestore _fakeFirestore;
  static late MockFirebaseAuth _mockFirebaseAuth;

  /// Initialize fake Firebase instances
  static void initialize() {
    _fakeFirestore = FakeFirebaseFirestore();
    _mockFirebaseAuth = MockFirebaseAuth();
  }

  /// Get provider overrides for testing
  static List<Override> get overrides => [
        firestoreProvider.overrideWithValue(_fakeFirestore),
        firebaseAuthProvider.overrideWithValue(_mockFirebaseAuth),
      ];

  /// Access to the fake Firestore instance for test setup
  static FakeFirebaseFirestore get fakeFirestore => _fakeFirestore;

  /// Access to the mock Auth instance for test setup
  static MockFirebaseAuth get mockFirebaseAuth => _mockFirebaseAuth;

  /// Clean up method to reset instances between tests
  static void cleanup() {
    // The fake instances don't need explicit cleanup,
    // but we can reinitialize them for fresh state
    initialize();
  }
}

/// Example usage in tests:
///
/// ```dart
/// void main() {
///   group('Repository Tests', () {
///     setUp(() {
///       FirebaseTestOverrides.initialize();
///     });
///
///     test('example test', () async {
///       // Arrange - Setup test data in fake Firestore
///       await FirebaseTestOverrides.fakeFirestore
///           .collection('users')
///           .doc('test-id')
///           .set({'name': 'Test User'});
///
///       // Create container with overrides
///       final container = ProviderContainer(
///         overrides: FirebaseTestOverrides.overrides,
///       );
///
///       // Act & Assert - Use real repositories with fake Firebase
///       final repository = container.read(authRepositoryProvider);
///       final result = await repository.getUserById('test-id');
///       expect(result?.firstName, equals('Test'));
///     });
///   });
/// }
/// ```
