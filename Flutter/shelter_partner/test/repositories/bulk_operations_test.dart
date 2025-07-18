import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/take_out_confirmation_repository.dart';
import 'package:shelter_partner/repositories/put_back_confirmation_repository.dart';
import 'package:shelter_partner/services/mock_logger_service.dart';

void main() {
  group('Bulk Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TakeOutConfirmationRepository takeOutRepo;
    late PutBackConfirmationRepository putBackRepo;
    late MockLoggerService mockLogger;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLogger = MockLoggerService();
      takeOutRepo = TakeOutConfirmationRepository(
        firestore: fakeFirestore,
        logger: mockLogger,
      );
      putBackRepo = PutBackConfirmationRepository(
        firestore: fakeFirestore,
        logger: mockLogger,
      );
    });

    test('bulk take out should process multiple animals efficiently', () async {
      // Setup test data
      const shelterId = 'test-shelter';
      final animals = [
        Animal(
          id: 'dog1',
          name: 'Buddy',
          species: 'dog',
          sex: 'male',
          monthsOld: 24,
          breed: 'Labrador',
          location: 'A1',
          fullLocation: 'Building A > A1',
          description: 'Friendly dog',
          symbol: '',
          symbolColor: '',
          takeOutAlert: '',
          putBackAlert: '',
          adoptionCategory: 'available',
          behaviorCategory: 'green',
          locationCategory: 'kennel',
          medicalCategory: 'healthy',
          volunteerCategory: 'all',
          inKennel: true,
          intakeDate: Timestamp.now(),
          photos: [],
          notes: [],
          logs: [
            Log(
              id: 'log1',
              type: 'intake',
              author: 'Staff',
              authorID: 'staff1',
              earlyReason: '',
              startTime: Timestamp.now(),
              endTime: Timestamp.now(),
            ),
          ],
          tags: [],
        ),
        Animal(
          id: 'cat1',
          name: 'Whiskers',
          species: 'cat',
          sex: 'female',
          monthsOld: 12,
          breed: 'Domestic Shorthair',
          location: 'C1',
          fullLocation: 'Building C > C1',
          description: 'Sweet cat',
          symbol: '',
          symbolColor: '',
          takeOutAlert: '',
          putBackAlert: '',
          adoptionCategory: 'available',
          behaviorCategory: 'green',
          locationCategory: 'kennel',
          medicalCategory: 'healthy',
          volunteerCategory: 'all',
          inKennel: true,
          intakeDate: Timestamp.now(),
          photos: [],
          notes: [],
          logs: [
            Log(
              id: 'log2',
              type: 'intake',
              author: 'Staff',
              authorID: 'staff1',
              earlyReason: '',
              startTime: Timestamp.now(),
              endTime: Timestamp.now(),
            ),
          ],
          tags: [],
        ),
      ];

      final logs = animals
          .map(
            (animal) => Log(
              id: 'takeout-${animal.id}',
              type: 'enrichment',
              author: 'Volunteer',
              authorID: 'vol1',
              earlyReason: '',
              startTime: Timestamp.now(),
              endTime: Timestamp.now(),
            ),
          )
          .toList();

      // Add animals to Firestore
      for (final animal in animals) {
        final collection = animal.species.toLowerCase() == 'cat'
            ? 'cats'
            : 'dogs';
        await fakeFirestore
            .collection('shelters/$shelterId/$collection')
            .doc(animal.id)
            .set(animal.toMap());
      }

      // Execute bulk take out
      await takeOutRepo.bulkTakeOutAnimals(animals, shelterId, logs);

      // Verify all animals are marked as not in kennel
      for (final animal in animals) {
        final collection = animal.species.toLowerCase() == 'cat'
            ? 'cats'
            : 'dogs';
        final doc = await fakeFirestore
            .collection('shelters/$shelterId/$collection')
            .doc(animal.id)
            .get();

        final data = doc.data()!;
        expect(data['inKennel'], false);
        expect((data['logs'] as List).length, animal.logs.length + 1);
      }
    });

    test('bulk put back should process multiple animals efficiently', () async {
      // Setup test data
      const shelterId = 'test-shelter';
      final animals = [
        Animal(
          id: 'dog1',
          name: 'Buddy',
          species: 'dog',
          sex: 'male',
          monthsOld: 24,
          breed: 'Labrador',
          location: 'A1',
          fullLocation: 'Building A > A1',
          description: 'Friendly dog',
          symbol: '',
          symbolColor: '',
          takeOutAlert: '',
          putBackAlert: '',
          adoptionCategory: 'available',
          behaviorCategory: 'green',
          locationCategory: 'kennel',
          medicalCategory: 'healthy',
          volunteerCategory: 'all',
          inKennel: false,
          intakeDate: Timestamp.now(),
          photos: [],
          notes: [],
          logs: [
            Log(
              id: 'log1',
              type: 'enrichment',
              author: 'Volunteer',
              authorID: 'vol1',
              earlyReason: '',
              startTime: Timestamp.now(),
              endTime: Timestamp.now(),
            ),
          ],
          tags: [],
        ),
      ];

      final logs = animals
          .map(
            (animal) => Log(
              id: 'putback-${animal.id}',
              type: 'enrichment',
              author: 'Volunteer',
              authorID: 'vol1',
              earlyReason: 'finished',
              startTime: Timestamp.now(),
              endTime: Timestamp.now(),
            ),
          )
          .toList();

      // Add animals to Firestore
      for (final animal in animals) {
        final collection = animal.species.toLowerCase() == 'cat'
            ? 'cats'
            : 'dogs';
        await fakeFirestore
            .collection('shelters/$shelterId/$collection')
            .doc(animal.id)
            .set(animal.toMap());
      }

      // Execute bulk put back
      await putBackRepo.bulkPutBackAnimals(animals, shelterId, logs);

      // Verify all animals are marked as in kennel
      for (final animal in animals) {
        final collection = animal.species.toLowerCase() == 'cat'
            ? 'cats'
            : 'dogs';
        final doc = await fakeFirestore
            .collection('shelters/$shelterId/$collection')
            .doc(animal.id)
            .get();

        final data = doc.data()!;
        expect(data['inKennel'], true);

        final animalLogs = (data['logs'] as List);
        expect(animalLogs.isNotEmpty, true);

        // Verify the last log was updated with earlyReason
        final lastLog = animalLogs.last as Map<String, dynamic>;
        expect(lastLog['earlyReason'], 'finished');
      }
    });

    test(
      'bulk delete last logs should process multiple animals efficiently',
      () async {
        // Setup test data
        const shelterId = 'test-shelter';
        final animals = [
          Animal(
            id: 'dog1',
            name: 'Buddy',
            species: 'dog',
            sex: 'male',
            monthsOld: 24,
            breed: 'Labrador',
            location: 'A1',
            fullLocation: 'Building A > A1',
            description: 'Friendly dog',
            symbol: '',
            symbolColor: '',
            takeOutAlert: '',
            putBackAlert: '',
            adoptionCategory: 'available',
            behaviorCategory: 'green',
            locationCategory: 'kennel',
            medicalCategory: 'healthy',
            volunteerCategory: 'all',
            inKennel: false,
            intakeDate: Timestamp.now(),
            photos: [],
            notes: [],
            logs: [
              Log(
                id: 'log1',
                type: 'intake',
                author: 'Staff',
                authorID: 'staff1',
                earlyReason: '',
                startTime: Timestamp.now(),
                endTime: Timestamp.now(),
              ),
              Log(
                id: 'log2',
                type: 'enrichment',
                author: 'Volunteer',
                authorID: 'vol1',
                earlyReason: '',
                startTime: Timestamp.now(),
                endTime: Timestamp.now(),
              ),
            ],
            tags: [],
          ),
        ];

        // Add animals to Firestore
        for (final animal in animals) {
          final collection = animal.species.toLowerCase() == 'cat'
              ? 'cats'
              : 'dogs';
          await fakeFirestore
              .collection('shelters/$shelterId/$collection')
              .doc(animal.id)
              .set(animal.toMap());
        }

        // Execute bulk delete last logs
        await putBackRepo.bulkDeleteLastLogs(animals, shelterId);

        // Verify last logs were deleted and animals marked as in kennel
        for (final animal in animals) {
          final collection = animal.species.toLowerCase() == 'cat'
              ? 'cats'
              : 'dogs';
          final doc = await fakeFirestore
              .collection('shelters/$shelterId/$collection')
              .doc(animal.id)
              .get();

          final data = doc.data()!;
          expect(data['inKennel'], true);

          final animalLogs = (data['logs'] as List);
          expect(animalLogs.length, animal.logs.length - 1);
        }
      },
    );
  });
}
