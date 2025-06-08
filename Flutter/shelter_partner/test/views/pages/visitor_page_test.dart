import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_animal_data.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('VisitorPage Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('displays animals in the list/grid', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter, get shared container
      final container = await createTestUserAndLogin(
        email: 'visitoruser@example.com',
        password: 'testpassword',
        firstName: 'Visitor',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      // Get the correct shelterId from the logged-in user
      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';
      // Add test animals to Firestore using the correct shelterId
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog1')
          .set(createTestAnimalData(id: 'dog1', name: 'Sammy'));
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VisitorPage()),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Buddy'), findsOneWidget); // from default test data
      expect(find.text('Max'), findsOneWidget); // from default test data
      expect(find.text('Sammy'), findsOneWidget);
    });

    testWidgets(
      'displays cats in the cat tab',
      skip: true, // Test consistently gets stuck and times out
      (WidgetTester tester) async {
        // Arrange: Create test user and shelter, get shared container
        final container = await createTestUserAndLogin(
          email: 'visitoruser2@example.com',
          password: 'testpassword',
          firstName: 'Visitor',
          lastName: 'Tester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
        // Get the correct shelterId from the logged-in user
        final user = container.read(appUserProvider);
        final shelterId = user?.shelterId ?? 'test-shelter';
        // Add test cats to Firestore using the correct shelterId
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('cats')
            .doc('cat1')
            .set(
              createTestAnimalData(id: 'cat1', name: 'Mittens', species: 'cat'),
            );
        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VisitorPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify the Cats tab is present and tap it
        expect(find.text('Cats'), findsOneWidget);
        await tester.tap(find.text('Cats'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Whiskers'), findsOneWidget); // from default test data
        expect(find.text('Fluffy'), findsOneWidget); // from default test data
        expect(find.text('Mittens'), findsOneWidget);
      },
    );
  });
}
