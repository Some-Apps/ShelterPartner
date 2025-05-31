import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/enrichment_page.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_animal_data.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('EnrichmentPage Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('displays animals in the list/grid',
        (WidgetTester tester) async {
      // Arrange: Create test user and shelter, get shared container
      final container = await createTestUserAndLogin(
        email: 'enrichmentuser@example.com',
        password: 'testpassword',
        firstName: 'Enrichment',
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
          child: const MaterialApp(
            home: EnrichmentPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Buddy'), findsOneWidget); // from default test data
      expect(find.text('Max'), findsOneWidget); // from default test data
      expect(find.text('Sammy'), findsOneWidget);
    });
  });
}
