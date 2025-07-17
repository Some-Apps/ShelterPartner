import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/add_log_repository.dart';
import '../helpers/firebase_test_overrides.dart';
import '../helpers/test_animal_data.dart';

void main() {
  group('AddLogRepository Analytics', () {
    late ProviderContainer container;

    setUp(() {
      FirebaseTestOverrides.initialize();
      container = ProviderContainer(overrides: FirebaseTestOverrides.overrides);
    });

    tearDown(() {
      container.dispose();
      FirebaseTestOverrides.cleanup();
    });

    test('should track analytics when log is completed', () async {
      // Arrange
      final repository = container.read(addLogRepositoryProvider);
      final mockAnalytics = FirebaseTestOverrides.mockAnalytics;

      const shelterID = 'test-shelter-123';
      final animal = createTestAnimal(
        id: 'test-animal-456',
        name: 'Fluffy',
        species: 'cat',
        location: 'A1',
      );

      final log = Log(
        id: 'test-log-789',
        type: 'walk',
        author: 'Test Author',
        authorID: 'test-author-123',
        startTime: Timestamp.now(),
        endTime: Timestamp.now(),
      );

      // Set up the animal document in fake Firestore
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters/$shelterID/cats')
          .doc(animal.id)
          .set(animal.toMap());

      // Act
      await repository.addLogToAnimal(animal, shelterID, log);

      // Assert
      expect(mockAnalytics.events, hasLength(1));
      expect(
        mockAnalytics.events.first,
        equals({
          'event': 'log_completed',
          'animal_id': animal.id,
          'animal_species': 'cat',
          'log_type': 'walk',
        }),
      );
    });

    test('should track analytics for different log types', () async {
      // Arrange
      final repository = container.read(addLogRepositoryProvider);
      final mockAnalytics = FirebaseTestOverrides.mockAnalytics;

      const shelterID = 'test-shelter-123';
      final animal = createTestAnimal(
        id: 'test-animal-789',
        name: 'Buddy',
        species: 'dog',
        location: 'B2',
      );

      final playLog = Log(
        id: 'test-log-play',
        type: 'play',
        author: 'Test Author',
        authorID: 'test-author-123',
        startTime: Timestamp.now(),
        endTime: Timestamp.now(),
      );

      // Set up the animal document in fake Firestore
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters/$shelterID/dogs')
          .doc(animal.id)
          .set(animal.toMap());

      // Act
      await repository.addLogToAnimal(animal, shelterID, playLog);

      // Assert
      expect(mockAnalytics.events, hasLength(1));
      expect(
        mockAnalytics.events.first,
        equals({
          'event': 'log_completed',
          'animal_id': animal.id,
          'animal_species': 'dog',
          'log_type': 'play',
        }),
      );
    });
  });
}
