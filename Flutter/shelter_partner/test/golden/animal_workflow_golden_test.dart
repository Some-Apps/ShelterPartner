@Tags(['golden'])
library animal_workflow_golden_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/utils/clock.dart';

import '../helpers/firebase_test_overrides.dart';
import '../helpers/mock_file_loader.dart';
import '../helpers/test_animal_data.dart';
import '../helpers/mock_clock.dart';

// Simple widget to display add log popup mockup
class TestAddLogDialog extends StatelessWidget {
  final Animal animal;

  const TestAddLogDialog({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(animal.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: null,
              items: const [
                DropdownMenuItem(value: 'walking', child: Text('Walking')),
                DropdownMenuItem(value: 'feeding', child: Text('Feeding')),
                DropdownMenuItem(value: 'grooming', child: Text('Grooming')),
                DropdownMenuItem(value: 'training', child: Text('Training')),
              ],
              onChanged: (String? newValue) {},
              decoration: const InputDecoration(
                hintText: 'Select log type...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: null,
              items: const [
                DropdownMenuItem(value: 'tired', child: Text('Tired')),
                DropdownMenuItem(value: 'not_interested', child: Text('Not interested')),
                DropdownMenuItem(value: 'too_excited', child: Text('Too excited')),
              ],
              onChanged: (String? newValue) {},
              decoration: const InputDecoration(
                hintText: 'Select early reason...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select start time...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select end time...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: null, // Disabled state for demo
          child: const Text('Save'),
        ),
      ],
    );
  }
}
class TestAnimalCard extends StatelessWidget {
  final Animal animal;

  const TestAnimalCard({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: animal.inKennel ? Colors.lightBlue.shade100 : Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pets,
                  color: animal.inKennel ? Colors.blue : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: animal.inKennel ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    animal.inKennel ? 'In Kennel' : 'Out',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Breed: ${animal.breed}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Location: ${animal.location}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Age: ${(animal.monthsOld / 12).round()} years',
              style: const TextStyle(fontSize: 14),
            ),
            if (animal.logs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Last activity: ${animal.logs.last.type}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void main() {
  testGoldens('Animal Workflow Golden Tests', (WidgetTester tester) async {
    FirebaseTestOverrides.initialize();
    await loadAppFonts();

    // Set up test data
    const String testUserId = 'test-user-id';
    const String testShelterId = 'test-shelter-id';
    final mockClock = MockClock(DateTime(2025, 1, 15, 10, 0, 0));

    // Create test user
    final testUser = AppUser(
      id: testUserId,
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      lastActivity: Timestamp.fromDate(mockClock.now()),
      type: 'admin',
      shelterId: testShelterId,
      accountSettings: null,
    );

    // Create test animals - some in kennel, some out
    final testAnimals = [
      createTestAnimal(
        id: 'dog1',
        name: 'Buddy',
        species: 'dog',
        breed: 'Golden Retriever',
        inKennel: true,
        location: 'Kennel A1',
        fullLocation: 'Building 1 > Room A > Kennel A1',
        logs: [
          Log(
            id: 'log1',
            type: 'put back',
            author: 'Test User',
            authorID: testUserId,
            earlyReason: '',
            startTime: Timestamp.fromDate(mockClock.now().subtract(const Duration(hours: 2))),
            endTime: Timestamp.fromDate(mockClock.now().subtract(const Duration(hours: 1))),
          ),
        ],
      ),
      createTestAnimal(
        id: 'cat1',
        name: 'Whiskers',
        species: 'cat',
        breed: 'Domestic Shorthair',
        inKennel: false,
        location: 'Room B1',
        fullLocation: 'Building 2 > Room B > Room B1',
        logs: [
          Log(
            id: 'log3',
            type: 'let out',
            author: 'Test User',
            authorID: testUserId,
            earlyReason: '',
            startTime: Timestamp.fromDate(mockClock.now().subtract(const Duration(minutes: 30))),
            endTime: Timestamp.fromDate(mockClock.now().add(const Duration(hours: 1))),
          ),
        ],
      ),
    ];

    // Create provider overrides for components that need them
    final List<Override> overrides = [
      ...FirebaseTestOverrides.overrides,
      authRepositoryProvider.overrideWith((ref) {
        final firestore = ref.watch(firestoreProvider);
        final firebaseAuth = ref.watch(firebaseAuthProvider);
        final logger = ref.watch(loggerServiceProvider);
        return AuthRepository(
          firestore: firestore,
          firebaseAuth: firebaseAuth,
          logger: logger,
          fileLoader: MockFileLoader(),
        );
      }),
      appUserProvider.overrideWith((ref) => testUser),
      clockProvider.overrideWithValue(mockClock),
    ];

    // 1. Screenshot: Animal card in kennel state (before being taken out)
    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TestAnimalCard(animal: testAnimals[0]), // Buddy - in kennel
          ),
        ),
      ),
      surfaceSize: const Size(400, 200),
    );

    await tester.pump();
    await screenMatchesGolden(tester, 'animal_workflow_01_animal_card_in_kennel');

    // 2. Show animal card in taken out state
    final takenOutAnimal = testAnimals[0].copyWith(inKennel: false);
    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TestAnimalCard(animal: takenOutAnimal),
          ),
        ),
      ),
      surfaceSize: const Size(400, 200),
    );

    await tester.pump();
    await screenMatchesGolden(tester, 'animal_workflow_02_animal_card_taken_out');

    // 3. Screenshot: When log popup is open (mock AddLogView component)
    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: TestAddLogDialog(animal: takenOutAnimal),
          ),
        ),
      ),
      surfaceSize: const Size(600, 800),
    );

    await tester.pump();
    await screenMatchesGolden(tester, 'animal_workflow_03_add_log_popup');

    // 4. Screenshot: Animal back in kennel after adding notes
    final animalBackInKennel = testAnimals[0].copyWith(
      inKennel: true,
      logs: [
        ...testAnimals[0].logs,
        Log(
          id: 'new-log',
          type: 'walking',
          author: 'Test User',
          authorID: testUserId,
          earlyReason: '',
          startTime: Timestamp.fromDate(mockClock.now().subtract(const Duration(minutes: 30))),
          endTime: Timestamp.fromDate(mockClock.now()),
        ),
      ],
    );

    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TestAnimalCard(animal: animalBackInKennel),
          ),
        ),
      ),
      surfaceSize: const Size(400, 200),
    );

    await tester.pump();
    await screenMatchesGolden(tester, 'animal_workflow_04_animal_back_in_kennel');

    // 5. Screenshot: Show multiple animals in different states for context
    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TestAnimalCard(animal: testAnimals[0]), // In kennel
                const SizedBox(height: 8),
                TestAnimalCard(animal: testAnimals[1]), // Out of kennel
              ],
            ),
          ),
        ),
      ),
      surfaceSize: const Size(400, 450),
    );

    await tester.pump();
    await screenMatchesGolden(tester, 'animal_workflow_05_multiple_animals_overview');
  });
}