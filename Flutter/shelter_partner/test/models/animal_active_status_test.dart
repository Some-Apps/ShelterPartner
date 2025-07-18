import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/models/animal.dart';
import '../helpers/test_animal_data.dart';

void main() {
  group('Animal Active Status Tests', () {
    test(
      'Animal should default to active when isActive field is missing from Firestore',
      () {
        // Arrange
        final firestoreData = {
          'name': 'TestDog',
          'sex': 'm',
          'monthsOld': 12,
          'species': 'dog',
          'breed': 'Mixed',
          'location': 'Kennel A',
          'fullLocation': 'Building 1 > Room A > Kennel 1',
          'description': 'A test dog',
          'symbol': 'pets',
          'symbolColor': 'brown',
          'takeOutAlert': 'Needs leash',
          'putBackAlert': 'Check water bowl',
          'adoptionCategory': 'Adoption 1',
          'behaviorCategory': 'Behavior 1',
          'locationCategory': 'Building 1',
          'medicalCategory': 'Medical 1',
          'volunteerCategory': 'Red',
          'inKennel': true,
          'intakeDate': Timestamp.now(),
          'photos': [],
          'notes': [],
          'logs': [],
          'tags': [],
          // Note: isActive field is intentionally missing
        };

        // Act
        final animal = Animal.fromFirestore(firestoreData, 'test-id');

        // Assert
        expect(
          animal.isActive,
          isTrue,
          reason:
              'Animal should default to active when isActive field is missing',
        );
      },
    );

    test('Animal should respect explicit isActive value from Firestore', () {
      // Arrange
      final activeAnimalData = createTestAnimalData(
        id: 'active-animal',
        name: 'ActiveDog',
        isActive: true,
      );
      final inactiveAnimalData = createTestAnimalData(
        id: 'inactive-animal',
        name: 'InactiveDog',
        isActive: false,
      );

      // Act
      final activeAnimal = Animal.fromFirestore(
        activeAnimalData,
        'active-animal',
      );
      final inactiveAnimal = Animal.fromFirestore(
        inactiveAnimalData,
        'inactive-animal',
      );

      // Assert
      expect(activeAnimal.isActive, isTrue);
      expect(inactiveAnimal.isActive, isFalse);
    });

    test('Animal copyWith should handle isActive field correctly', () {
      // Arrange
      final animal = createTestAnimal(
        id: 'test',
        name: 'TestDog',
        isActive: true,
      );

      // Act
      final inactiveAnimal = animal.copyWith(isActive: false);
      final activeAnimal = inactiveAnimal.copyWith(isActive: true);
      final unchangedAnimal = animal.copyWith(name: 'NewName');

      // Assert
      expect(inactiveAnimal.isActive, isFalse);
      expect(activeAnimal.isActive, isTrue);
      expect(
        unchangedAnimal.isActive,
        isTrue,
        reason: 'isActive should remain unchanged when not specified',
      );
    });

    test('Animal toMap should include isActive field', () {
      // Arrange
      final activeAnimal = createTestAnimal(
        id: 'test',
        name: 'TestDog',
        isActive: true,
      );
      final inactiveAnimal = createTestAnimal(
        id: 'test',
        name: 'TestDog',
        isActive: false,
      );

      // Act
      final activeMap = activeAnimal.toMap();
      final inactiveMap = inactiveAnimal.toMap();

      // Assert
      expect(activeMap['isActive'], isTrue);
      expect(inactiveMap['isActive'], isFalse);
    });

    test('Test helper functions should create animals with isActive field', () {
      // Arrange & Act
      final activeAnimal = createTestAnimal(
        id: 'test',
        name: 'TestDog',
        isActive: true,
      );
      final inactiveAnimal = createTestAnimal(
        id: 'test',
        name: 'TestDog',
        isActive: false,
      );
      final defaultAnimal = createTestAnimal(
        id: 'test',
        name: 'TestDog',
      ); // Should default to active

      final activeData = createTestAnimalData(
        id: 'test',
        name: 'TestDog',
        isActive: true,
      );
      final inactiveData = createTestAnimalData(
        id: 'test',
        name: 'TestDog',
        isActive: false,
      );

      // Assert
      expect(activeAnimal.isActive, isTrue);
      expect(inactiveAnimal.isActive, isFalse);
      expect(
        defaultAnimal.isActive,
        isTrue,
        reason: 'Should default to active',
      );
      expect(activeData['isActive'], isTrue);
      expect(inactiveData['isActive'], isFalse);
    });
  });
}
