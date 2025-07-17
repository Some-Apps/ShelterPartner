import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/repositories/add_note_repository.dart';
import '../helpers/firebase_test_overrides.dart';
import '../helpers/test_animal_data.dart';

void main() {
  group('AddNoteRepository Analytics', () {
    late ProviderContainer container;

    setUp(() {
      FirebaseTestOverrides.initialize();
      container = ProviderContainer(overrides: FirebaseTestOverrides.overrides);
    });

    tearDown(() {
      container.dispose();
      FirebaseTestOverrides.cleanup();
    });

    test('should track analytics when note is added', () async {
      // Arrange
      final repository = container.read(addNoteRepositoryProvider);
      final mockAnalytics = FirebaseTestOverrides.mockAnalytics;

      const shelterID = 'test-shelter-123';
      final animal = createTestAnimal(
        id: 'test-animal-456',
        name: 'Fluffy',
        species: 'cat',
        location: 'A1',
      );

      final note = Note(
        id: 'test-note-789',
        note: 'Test note content',
        author: 'Test Author',
        authorID: 'test-author-123',
        timestamp: Timestamp.now(),
      );

      // Set up the animal document in fake Firestore
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters/$shelterID/cats')
          .doc(animal.id)
          .set(animal.toMap());

      // Act
      await repository.addNoteToAnimal(animal, shelterID, note);

      // Assert
      expect(mockAnalytics.events, hasLength(1));
      expect(
        mockAnalytics.events.first,
        equals({
          'event': 'note_added',
          'animal_id': animal.id,
          'animal_species': 'cat',
        }),
      );
    });

    test('should track analytics when tag is added', () async {
      // Arrange
      final repository = container.read(addNoteRepositoryProvider);
      final mockAnalytics = FirebaseTestOverrides.mockAnalytics;

      const shelterID = 'test-shelter-123';
      const tagName = 'friendly';
      final animal = createTestAnimal(
        id: 'test-animal-789',
        name: 'Buddy',
        species: 'dog',
        location: 'B2',
      );

      // Set up the animal document in fake Firestore
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters/$shelterID/dogs')
          .doc(animal.id)
          .set(animal.toMap());

      // Act
      await repository.updateAnimalTags(animal, shelterID, tagName);

      // Assert
      expect(mockAnalytics.events, hasLength(1));
      expect(
        mockAnalytics.events.first,
        equals({
          'event': 'tag_added',
          'animal_id': animal.id,
          'animal_species': 'dog',
          'tag_name': tagName,
        }),
      );
    });
  });
}
