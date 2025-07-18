import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/components/add_log_view.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_animal_data.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('AddLogView Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('should display with proper initialization', (WidgetTester tester) async {
      // Create authenticated test user and shelter
      final container = await createTestUserAndLogin(
        email: 'testuser@example.com',
        password: 'testpassword',
        firstName: 'Test',
        lastName: 'User',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      // Create a test animal
      final animal = createTestAnimal(
        id: 'test-id',
        name: 'Test Dog',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AddLogView(animal: animal),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the dialog is displayed
      expect(find.text('Test Dog'), findsOneWidget);
      
      // Verify all input fields are present
      expect(find.text('Select log type...'), findsOneWidget);
      expect(find.text('Select early reason...'), findsOneWidget);
      
      // Verify time and duration fields are present (they have default values)
      final startTimeField = find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Start time');
      expect(startTimeField, findsOneWidget);
      
      final endTimeField = find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'End time');
      expect(endTimeField, findsOneWidget);
      
      final durationField = find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Duration (minutes)');
      expect(durationField, findsOneWidget);
      
      // Verify duration field shows 30 minutes (default)
      expect(find.text('30'), findsOneWidget);
      
      // Verify Save and Cancel buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}