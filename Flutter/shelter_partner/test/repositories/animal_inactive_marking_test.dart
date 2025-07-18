import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/repositories/animal_card_repository.dart';
import 'package:shelter_partner/models/animal.dart';
import '../helpers/firebase_test_overrides.dart';
import '../helpers/test_animal_data.dart';

void main() {
  group('Animal Card Repository Mark Inactive Tests', () {
    late FirebaseFirestore fakeFirestore;
    late AnimalRepository animalRepository;
    const String testShelterId = 'test-shelter-id';

    setUp(() {
      FirebaseTestOverrides.initialize();
      fakeFirestore = FirebaseTestOverrides.fakeFirestore;
      animalRepository = AnimalRepository(firestore: fakeFirestore);
    });

    group('markAnimalAsInactive', () {
      test('should mark a dog as inactive', () async {
        // Arrange: Create an active dog
        final dogData = createTestAnimalData(
          id: 'test-dog',
          name: 'TestDog',
          species: 'dog',
          isActive: true,
        );
        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('test-dog')
            .set(dogData);

        // Verify the dog is initially active
        final initialDoc = await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('test-dog')
            .get();
        expect(initialDoc.data()?['isActive'], isTrue);

        // Act: Mark the dog as inactive
        await animalRepository.markAnimalAsInactive(
          testShelterId,
          'dog',
          'test-dog',
        );

        // Assert: Verify the dog is now inactive
        final updatedDoc = await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('test-dog')
            .get();
        expect(updatedDoc.data()?['isActive'], isFalse);

        // Verify other fields remain unchanged
        expect(updatedDoc.data()?['name'], 'TestDog');
        expect(updatedDoc.data()?['species'], 'dog');
      });

      test('should mark a cat as inactive', () async {
        // Arrange: Create an active cat
        final catData = createTestAnimalData(
          id: 'test-cat',
          name: 'TestCat',
          species: 'cat',
          isActive: true,
        );
        await fakeFirestore
            .collection('shelters/$testShelterId/cats')
            .doc('test-cat')
            .set(catData);

        // Act: Mark the cat as inactive
        await animalRepository.markAnimalAsInactive(
          testShelterId,
          'cat',
          'test-cat',
        );

        // Assert: Verify the cat is now inactive
        final updatedDoc = await fakeFirestore
            .collection('shelters/$testShelterId/cats')
            .doc('test-cat')
            .get();
        expect(updatedDoc.data()?['isActive'], isFalse);
      });

      test('should handle marking already inactive animal as inactive', () async {
        // Arrange: Create an already inactive animal
        final dogData = createTestAnimalData(
          id: 'inactive-dog',
          name: 'InactiveDog',
          species: 'dog',
          isActive: false,
        );
        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('inactive-dog')
            .set(dogData);

        // Act: Mark the already inactive dog as inactive (should not throw error)
        await animalRepository.markAnimalAsInactive(
          testShelterId,
          'dog',
          'inactive-dog',
        );

        // Assert: Verify the dog remains inactive
        final updatedDoc = await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('inactive-dog')
            .get();
        expect(updatedDoc.data()?['isActive'], isFalse);
      });

      test('should work with updateAnimal method for consistency', () async {
        // Arrange: Create an active animal
        final animal = createTestAnimal(
          id: 'consistency-test',
          name: 'ConsistencyDog',
          species: 'dog',
          isActive: true,
        );
        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('consistency-test')
            .set(animal.toMap());

        // Act: First mark as inactive using our new method
        await animalRepository.markAnimalAsInactive(
          testShelterId,
          'dog',
          'consistency-test',
        );

        // Then update using the regular updateAnimal method to mark as active again
        final updatedAnimal = animal.copyWith(isActive: true);
        await animalRepository.updateAnimal(
          testShelterId,
          'dog',
          updatedAnimal,
        );

        // Assert: Verify the animal is active again
        final finalDoc = await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('consistency-test')
            .get();
        expect(finalDoc.data()?['isActive'], isTrue);
      });
    });

    group('Integration with Animal Model', () {
      test(
        'inactive animal should be properly created from Firestore after marking inactive',
        () async {
          // Arrange: Create and save an active animal
          final animal = createTestAnimal(
            id: 'integration-test',
            name: 'IntegrationDog',
            species: 'dog',
            isActive: true,
          );
          await fakeFirestore
              .collection('shelters/$testShelterId/dogs')
              .doc('integration-test')
              .set(animal.toMap());

          // Act: Mark as inactive
          await animalRepository.markAnimalAsInactive(
            testShelterId,
            'dog',
            'integration-test',
          );

          // Retrieve from Firestore and create Animal object
          final doc = await fakeFirestore
              .collection('shelters/$testShelterId/dogs')
              .doc('integration-test')
              .get();
          final retrievedAnimal = Animal.fromFirestore(doc.data()!, doc.id);

          // Assert: Animal should be properly marked as inactive
          expect(retrievedAnimal.isActive, isFalse);
          expect(retrievedAnimal.id, 'integration-test');
          expect(retrievedAnimal.name, 'IntegrationDog');
        },
      );
    });
  });
}
