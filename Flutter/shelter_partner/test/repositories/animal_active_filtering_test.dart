import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/repositories/enrichment_repository.dart';
import 'package:shelter_partner/repositories/visitors_repository.dart';
import 'package:shelter_partner/repositories/stats_repository.dart';
import '../helpers/firebase_test_overrides.dart';
import '../helpers/test_animal_data.dart';

void main() {
  group('Animal Repository Active Filtering Tests', () {
    late FirebaseFirestore fakeFirestore;
    late EnrichmentRepository enrichmentRepo;
    late VisitorsRepository visitorsRepo;
    late StatsRepository statsRepo;
    const String testShelterId = 'test-shelter-id';

    setUp(() {
      FirebaseTestOverrides.initialize();
      fakeFirestore = FirebaseTestOverrides.fakeFirestore;
      enrichmentRepo = EnrichmentRepository(firestore: fakeFirestore);
      visitorsRepo = VisitorsRepository(firestore: fakeFirestore);
      statsRepo = StatsRepository(firestore: fakeFirestore);
    });

    group('EnrichmentRepository', () {
      test('should only fetch active animals', () async {
        // Arrange: Add both active and inactive animals
        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('active-dog')
            .set(
              createTestAnimalData(
                id: 'active-dog',
                name: 'ActiveDog',
                isActive: true,
              ),
            );

        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('inactive-dog')
            .set(
              createTestAnimalData(
                id: 'inactive-dog',
                name: 'InactiveDog',
                isActive: false,
              ),
            );

        await fakeFirestore
            .collection('shelters/$testShelterId/cats')
            .doc('active-cat')
            .set(
              createTestAnimalData(
                id: 'active-cat',
                name: 'ActiveCat',
                species: 'cat',
                isActive: true,
              ),
            );

        await fakeFirestore
            .collection('shelters/$testShelterId/cats')
            .doc('inactive-cat')
            .set(
              createTestAnimalData(
                id: 'inactive-cat',
                name: 'InactiveCat',
                species: 'cat',
                isActive: false,
              ),
            );

        // Act: Fetch animals
        final animalsStream = enrichmentRepo.fetchAnimals(testShelterId);
        final animals = await animalsStream.first;

        // Assert: Should only get active animals
        expect(animals.length, 2);
        expect(animals.any((animal) => animal.name == 'ActiveDog'), isTrue);
        expect(animals.any((animal) => animal.name == 'ActiveCat'), isTrue);
        expect(animals.any((animal) => animal.name == 'InactiveDog'), isFalse);
        expect(animals.any((animal) => animal.name == 'InactiveCat'), isFalse);

        // Verify all returned animals are active
        for (final animal in animals) {
          expect(animal.isActive, isTrue);
        }
      });

      test('should handle when no active animals exist', () async {
        // Arrange: Add only inactive animals
        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('inactive-dog1')
            .set(
              createTestAnimalData(
                id: 'inactive-dog1',
                name: 'InactiveDog1',
                isActive: false,
              ),
            );

        await fakeFirestore
            .collection('shelters/$testShelterId/cats')
            .doc('inactive-cat1')
            .set(
              createTestAnimalData(
                id: 'inactive-cat1',
                name: 'InactiveCat1',
                species: 'cat',
                isActive: false,
              ),
            );

        // Act: Fetch animals
        final animalsStream = enrichmentRepo.fetchAnimals(testShelterId);
        final animals = await animalsStream.first;

        // Assert: Should return empty list
        expect(animals, isEmpty);
      });
    });

    group('VisitorsRepository', () {
      test('should only fetch active animals', () async {
        // Arrange: Add both active and inactive animals
        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('visitor-active-dog')
            .set(
              createTestAnimalData(
                id: 'visitor-active-dog',
                name: 'VisitorActiveDog',
                isActive: true,
              ),
            );

        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('visitor-inactive-dog')
            .set(
              createTestAnimalData(
                id: 'visitor-inactive-dog',
                name: 'VisitorInactiveDog',
                isActive: false,
              ),
            );

        // Act: Fetch animals
        final animalsStream = visitorsRepo.fetchAnimals(testShelterId);
        final animals = await animalsStream.first;

        // Assert: Should only get active animals
        expect(animals.length, 1);
        expect(animals.first.name, 'VisitorActiveDog');
        expect(animals.first.isActive, isTrue);
      });
    });

    group('StatsRepository', () {
      test('should only fetch active animals for stats calculation', () async {
        // Arrange: Add both active and inactive animals
        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('stats-active-dog')
            .set(
              createTestAnimalData(
                id: 'stats-active-dog',
                name: 'StatsActiveDog',
                isActive: true,
              ),
            );

        await fakeFirestore
            .collection('shelters/$testShelterId/dogs')
            .doc('stats-inactive-dog')
            .set(
              createTestAnimalData(
                id: 'stats-inactive-dog',
                name: 'StatsInactiveDog',
                isActive: false,
              ),
            );

        // Act: Fetch animals
        final animalsStream = statsRepo.fetchAnimals(testShelterId);
        final animals = await animalsStream.first;

        // Assert: Should only get active animals for stats
        expect(animals.length, 1);
        expect(animals.first.name, 'StatsActiveDog');
        expect(animals.first.isActive, isTrue);
      });
    });

    group('Cross-Repository Consistency', () {
      test('all repositories should return the same active animals', () async {
        // Arrange: Add mixed active/inactive animals
        final activeDogsData = [
          createTestAnimalData(id: 'dog1', name: 'ActiveDog1', isActive: true),
          createTestAnimalData(id: 'dog2', name: 'ActiveDog2', isActive: true),
        ];
        final inactiveDogsData = [
          createTestAnimalData(
            id: 'dog3',
            name: 'InactiveDog1',
            isActive: false,
          ),
        ];
        final activeCatsData = [
          createTestAnimalData(
            id: 'cat1',
            name: 'ActiveCat1',
            species: 'cat',
            isActive: true,
          ),
        ];
        final inactiveCatsData = [
          createTestAnimalData(
            id: 'cat2',
            name: 'InactiveCat1',
            species: 'cat',
            isActive: false,
          ),
        ];

        // Add all animals to Firestore
        for (var i = 0; i < activeDogsData.length; i++) {
          await fakeFirestore
              .collection('shelters/$testShelterId/dogs')
              .doc('dog${i + 1}')
              .set(activeDogsData[i]);
        }
        for (var data in inactiveDogsData) {
          await fakeFirestore
              .collection('shelters/$testShelterId/dogs')
              .doc('dog3')
              .set(data);
        }
        for (var data in activeCatsData) {
          await fakeFirestore
              .collection('shelters/$testShelterId/cats')
              .doc('cat1')
              .set(data);
        }
        for (var data in inactiveCatsData) {
          await fakeFirestore
              .collection('shelters/$testShelterId/cats')
              .doc('cat2')
              .set(data);
        }

        // Act: Fetch from all repositories
        final enrichmentAnimals = await enrichmentRepo
            .fetchAnimals(testShelterId)
            .first;
        final visitorsAnimals = await visitorsRepo
            .fetchAnimals(testShelterId)
            .first;
        final statsAnimals = await statsRepo.fetchAnimals(testShelterId).first;

        // Assert: All repositories should return the same active animals
        expect(enrichmentAnimals.length, 3); // 2 active dogs + 1 active cat
        expect(visitorsAnimals.length, 3);
        expect(statsAnimals.length, 3);

        // Check that all returned animals are active
        for (final animal in enrichmentAnimals) {
          expect(animal.isActive, isTrue);
        }
        for (final animal in visitorsAnimals) {
          expect(animal.isActive, isTrue);
        }
        for (final animal in statsAnimals) {
          expect(animal.isActive, isTrue);
        }

        // Check that all repositories return the same animal names
        final enrichmentNames = enrichmentAnimals.map((a) => a.name).toSet();
        final visitorsNames = visitorsAnimals.map((a) => a.name).toSet();
        final statsNames = statsAnimals.map((a) => a.name).toSet();

        expect(enrichmentNames, equals(visitorsNames));
        expect(visitorsNames, equals(statsNames));
        expect(
          enrichmentNames,
          containsAll(['ActiveDog1', 'ActiveDog2', 'ActiveCat1']),
        );
      });
    });
  });
}
