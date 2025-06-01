import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/utils/clock.dart';
import 'package:shelter_partner/views/components/animal_card_image.dart';
import 'package:shelter_partner/views/components/animal_card_view.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/models/tag.dart';
import 'package:shelter_partner/models/animal.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_animal_data.dart';
import '../../helpers/test_auth_helpers.dart';
import '../../helpers/test_firestore_helpers.dart';
import '../../helpers/mock_clock.dart';

void main() {
  group('AnimalCardView Integration Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets("allows taking out an animal", (WidgetTester tester) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'animalcarduser1@example.com',
        password: 'testpassword',
        firstName: 'Animal',
        lastName: 'CardTester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      final mockClock = container.read(clockProvider) as MockClock;
      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId as String;
      expect(shelterId, isNotNull, reason: 'Shelter ID should not be null');
      // Add a test animal to Firestore
      final animal = createTestAnimal(
        id: 'dog1',
        name: 'TestDog',
      );
      await addAnimalToFirestore(
        firestore: FirebaseTestOverrides.fakeFirestore,
        shelterId: shelterId,
        animal: animal,
      );
      // Preload the account settings viewmodel and wait for it to load
      while (container.read(accountSettingsViewModelProvider).isLoading) {
        await tester.pump();
      }
      // Check the value of inKennel in Firestore directly (initial state)
      final initialDoc = await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc(animal.id)
          .get();
      final initialData = initialDoc.data()!;
      expect(
        initialData['inKennel'],
        isTrue,
        reason: 'Animal should start in kennel',
      );
      // Act: Render the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalCardView(animal: animal, maxLocationTiers: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Find the animal image (which is the GestureDetector)
      final imageFinder = find.byType(AnimalCardImage);
      expect(imageFinder, findsOneWidget);
      // Simulate a long press to take out the animal
      final gesture = await tester.startGesture(tester.getCenter(imageFinder));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      mockClock.advance(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      // Check the value of inKennel in Firestore directly
      final doc = await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc(animal.id)
          .get();
      final data = doc.data()!;
      expect(data['inKennel'], isFalse,
          reason: 'Animal should be taken out after long press');

      // Rebuild the widget with the updated animal from Firestore
      final updatedAnimal = Animal.fromFirestore(data, animal.id);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalCardView(animal: updatedAnimal, maxLocationTiers: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that the card background color is orange and '0 minutes' appears
      final cardFinder = find.byType(Card);
      final cardWidget = tester.widget<Card>(cardFinder.first);
      expect(cardWidget.color, equals(Colors.orange.shade100),
          reason: 'Card background should be orange when taken out');
      expect(find.textContaining('0 minutes'), findsOneWidget,
          reason: 'Should show 0 minutes when taken out');
    });

    testWidgets("allows putting an animal back in the kennel",
        (WidgetTester tester) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'animalcarduser1@example.com',
        password: 'testpassword',
        firstName: 'Animal',
        lastName: 'CardTester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      final mockClock = container.read(clockProvider) as MockClock;
      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId as String;
      expect(shelterId, isNotNull, reason: 'Shelter ID should not be null');
      // Add a test animal to Firestore, already out of kennel
      final animal = createTestAnimal(
        id: 'dog1',
        name: 'TestDog',
        inKennel: false,
      );
      await addAnimalToFirestore(
        firestore: FirebaseTestOverrides.fakeFirestore,
        shelterId: shelterId,
        animal: animal,
      );
      // Preload the account settings viewmodel and wait for it to load
      while (container.read(accountSettingsViewModelProvider).isLoading) {
        await tester.pump();
      }
      // Act: Render the widget with animal out of kennel
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalCardView(animal: animal, maxLocationTiers: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Find the animal image (which is the GestureDetector)
      final imageFinder = find.byType(AnimalCardImage);
      expect(imageFinder, findsOneWidget);
      // Simulate a long press to put the animal back in the kennel
      final gesture = await tester.startGesture(tester.getCenter(imageFinder));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      mockClock.advance(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      // Check the value of inKennel in Firestore directly (should be true again)
      final doc = await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc(animal.id)
          .get();
      final data = doc.data()!;
      expect(data['inKennel'], isTrue,
          reason: 'Animal should be put back in kennel after long press');

      // Rebuild the widget with the updated animal from Firestore
      final updatedAnimal = Animal.fromFirestore(data, animal.id);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalCardView(animal: updatedAnimal, maxLocationTiers: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Optionally, check that the card background color is light blue again
      final cardFinder = find.byType(Card);
      final cardWidget = tester.widget<Card>(cardFinder.first);
      expect(cardWidget.color, equals(Colors.lightBlue.shade100),
          reason:
              'Card background should be light blue when put back in kennel');
    });

    testWidgets('displays all expected animal fields',
        (WidgetTester tester) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'animalcarduser2@example.com',
        password: 'testpassword',
        firstName: 'Animal',
        lastName: 'CardTester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';
      // Add a test animal to Firestore using helper, with all fields and 5 tags
      final animal = createTestAnimal(
        id: 'dog2',
        name: 'Name',
        sex: 'm',
        monthsOld: 24,
        species: 'dog',
        breed: 'Breed',
        location: 'Location',
        fullLocation: 'Shelter A > Building 2 > Room B > Kennel 2',
        description: 'Description.',
        symbol: 'pets',
        symbolColor: 'brown',
        adoptionCategory: 'Adoption Category',
        behaviorCategory: 'Behavior Category',
        locationCategory: 'Location Category',
        medicalCategory: 'Medical Category',
        volunteerCategory: 'Volunteer Category',
        tags: [
          Tag(id: 'tag1', title: 'Tag1', count: 5, timestamp: Timestamp.now()),
          Tag(id: 'tag2', title: 'Tag2', count: 4, timestamp: Timestamp.now()),
          Tag(id: 'tag3', title: 'Tag3', count: 3, timestamp: Timestamp.now()),
          Tag(id: 'tag4', title: 'Tag4', count: 2, timestamp: Timestamp.now()),
          Tag(id: 'tag5', title: 'Tag5', count: 1, timestamp: Timestamp.now()),
        ],
      );
      await addAnimalToFirestore(
        firestore: FirebaseTestOverrides.fakeFirestore,
        shelterId: shelterId,
        animal: animal,
      );
      // Act: Render the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AnimalCardView(animal: animal, maxLocationTiers: 3),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert: All expected fields are visible
      // Animal image
      expect(find.byType(AnimalCardImage), findsOneWidget);
      // Animal name
      expect(find.text('Name'), findsOneWidget);
      // Symbol icon (pets)
      expect(find.byIcon(Icons.pets), findsOneWidget);
      // Location tiers: Building 2, Room B, Kennel 2 (maxLocationTiers=3)
      expect(find.text('Building 2'), findsOneWidget);
      expect(find.text('Room B'), findsOneWidget);
      expect(find.text('Kennel 2'), findsOneWidget);
      // Info chips for categories
      expect(find.text('Adoption Category'), findsOneWidget);
      expect(find.text('Behavior Category'), findsOneWidget);
      expect(find.text('Location Category'), findsOneWidget);
      expect(find.text('Medical Category'), findsOneWidget);
      expect(find.text('Volunteer Category'), findsOneWidget);
      // Alerts
      // Only the top 3 tags by count should be shown
      expect(find.text('Tag1'), findsOneWidget);
      expect(find.text('Tag2'), findsOneWidget);
      expect(find.text('Tag3'), findsOneWidget);
      expect(find.text('Tag4'), findsNothing);
      expect(find.text('Tag5'), findsNothing);
      // Time since last log (should contain 'minute', 'hour', 'day', or 'week')
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            (widget.data?.contains('minute') == true ||
                widget.data?.contains('hour') == true ||
                widget.data?.contains('day') == true ||
                widget.data?.contains('week') == true)),
        findsWidgets,
      );
      // Author of last log
      expect(find.text(animal.logs.last.author), findsOneWidget);
      // Popup menu button (more_vert)
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });
}
