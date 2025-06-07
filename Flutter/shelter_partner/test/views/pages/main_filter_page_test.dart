import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:shelter_partner/models/filter_condition.dart';
import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('MainFilterPage Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('displays filter page with correct title', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user
      final container = await createTestUserAndLogin(
        email: 'filteruser@example.com',
        password: 'testpassword',
        firstName: 'Filter',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      const testTitle = 'User Enrichment Filter';

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainFilterPage(
              title: testTitle,
              collection: 'users',
              documentID: 'test-user-id',
              filterFieldPath: 'userFilter',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(testTitle), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('allows adding a filter condition', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user
      final container = await createTestUserAndLogin(
        email: 'addconditionuser@example.com',
        password: 'testpassword',
        firstName: 'Add',
        lastName: 'ConditionTester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      const testTitle = 'User Enrichment Filter';

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainFilterPage(
              title: testTitle,
              collection: 'users',
              documentID: 'test-user-id',
              filterFieldPath: 'userFilter',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert initial state - should show "Add Condition" button when no filters exist
      expect(find.text('Add Condition'), findsOneWidget);
      
      // Act - tap the "Add Condition" button
      await tester.tap(find.text('Add Condition'));
      await tester.pumpAndSettle();

      // Assert - dialog should open
      expect(find.text('Add Condition'), findsWidgets); // Button and dialog title
      expect(find.byType(AlertDialog), findsOneWidget);
      
      // Find and interact with the attribute dropdown
      final attributeDropdown = find.byType(DropdownButton<String>).first;
      expect(attributeDropdown, findsOneWidget);
      
      // The default attribute should be 'Name'
      expect(find.text('Name'), findsWidgets);
      
      // Find and interact with the operator dropdown
      final operatorDropdown = find.byType(DropdownButton<OperatorType>);
      expect(operatorDropdown, findsOneWidget);
      
      // Tap operator dropdown to see available options
      await tester.tap(operatorDropdown);
      await tester.pumpAndSettle();
      
      // Should see operator options for name attribute
      expect(find.text('Equals'), findsOneWidget);
      expect(find.text('Contains'), findsOneWidget);
      
      // Select "Contains" operator
      await tester.tap(find.text('Contains'));
      await tester.pumpAndSettle();
      
      // Find the value text field and enter a value
      final valueField = find.byType(TextField);
      expect(valueField, findsOneWidget);
      await tester.enterText(valueField, 'test-value');
      await tester.pumpAndSettle();
      
      // Find and tap the "Add" button in the dialog
      final addButton = find.text('Add').last;
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      
      // Assert - condition should be added and dialog should close
      expect(find.byType(AlertDialog), findsNothing);
      
      // Should now show the filter expression
      expect(find.textContaining('Name'), findsWidgets);
      expect(find.textContaining('Contains'), findsWidgets);
      expect(find.textContaining('test-value'), findsWidgets);
    });

    testWidgets('allows changing filter attribute and operator types', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user
      final container = await createTestUserAndLogin(
        email: 'changeattributeuser@example.com',
        password: 'testpassword',
        firstName: 'Change',
        lastName: 'AttributeTester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      const testTitle = 'User Enrichment Filter';

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainFilterPage(
              title: testTitle,
              collection: 'users',
              documentID: 'test-user-id',
              filterFieldPath: 'userFilter',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - tap the "Add Condition" button
      await tester.tap(find.text('Add Condition'));
      await tester.pumpAndSettle();

      // Change attribute to 'Breed'
      final attributeDropdown = find.byType(DropdownButton<String>).first;
      await tester.tap(attributeDropdown);
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Breed'));
      await tester.pumpAndSettle();
      
      // The operator dropdown should now show operators available for 'breed'
      final operatorDropdown = find.byType(DropdownButton<OperatorType>);
      await tester.tap(operatorDropdown);
      await tester.pumpAndSettle();
      
      // Should see text operators for breed
      expect(find.text('Equals'), findsOneWidget);
      expect(find.text('Not Equals'), findsOneWidget);
      
      // Select "Equals" operator
      await tester.tap(find.text('Equals'));
      await tester.pumpAndSettle();
      
      // Enter a breed value
      final valueField = find.byType(TextField);
      await tester.enterText(valueField, 'Labrador');
      await tester.pumpAndSettle();
      
      // Add the condition
      final addButton = find.text('Add').last;
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      
      // Assert - should show breed filter
      expect(find.textContaining('Breed'), findsWidgets);
      expect(find.textContaining('Equals'), findsWidgets);
      expect(find.textContaining('Labrador'), findsWidgets);
    });

    testWidgets('supports numerical attributes with appropriate operators', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user
      final container = await createTestUserAndLogin(
        email: 'numericaluser@example.com',
        password: 'testpassword',
        firstName: 'Numerical',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      const testTitle = 'User Enrichment Filter';

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainFilterPage(
              title: testTitle,
              collection: 'users',
              documentID: 'test-user-id',
              filterFieldPath: 'userFilter',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - tap the "Add Condition" button
      await tester.tap(find.text('Add Condition'));
      await tester.pumpAndSettle();

      // Change attribute to 'Sex' (which should have equals/not equals operators)
      final attributeDropdown = find.byType(DropdownButton<String>).first;
      await tester.tap(attributeDropdown);
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Sex'));
      await tester.pumpAndSettle();
      
      // The operator dropdown should now show text operators
      final operatorDropdown = find.byType(DropdownButton<OperatorType>);
      await tester.tap(operatorDropdown);
      await tester.pumpAndSettle();
      
      // Should see simple operators for sex
      expect(find.text('Equals'), findsOneWidget);
      expect(find.text('Not Equals'), findsOneWidget);
      
      // Select "Equals" operator
      await tester.tap(find.text('Equals'));
      await tester.pumpAndSettle();
      
      // Enter a value
      final valueField = find.byType(TextField);
      expect(valueField, findsOneWidget);
      await tester.enterText(valueField, 'Male');
      await tester.pumpAndSettle();
      
      // Add the condition
      final addButton = find.text('Add').last;
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      
      // Assert - should show filter
      expect(find.textContaining('Sex'), findsWidgets);
      expect(find.textContaining('Equals'), findsWidgets);
      expect(find.textContaining('Male'), findsWidgets);
    });

    testWidgets('can remove filter conditions', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user
      final container = await createTestUserAndLogin(
        email: 'removeuser@example.com',
        password: 'testpassword',
        firstName: 'Remove',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      const testTitle = 'User Enrichment Filter';

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainFilterPage(
              title: testTitle,
              collection: 'users',
              documentID: 'test-user-id',
              filterFieldPath: 'userFilter',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add a condition first
      await tester.tap(find.text('Add Condition'));
      await tester.pumpAndSettle();
      
      // Select default operator (should be auto-selected for 'Name')
      final operatorDropdown = find.byType(DropdownButton<OperatorType>);
      await tester.tap(operatorDropdown);
      await tester.pumpAndSettle();
      
      // Select 'Contains' operator
      await tester.tap(find.text('Contains'));
      await tester.pumpAndSettle();
      
      final valueField = find.byType(TextField);
      await tester.enterText(valueField, 'test-value');
      await tester.pumpAndSettle();
      
      final addButton = find.text('Add').last;
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      
      // Verify condition was added
      expect(find.textContaining('test-value'), findsOneWidget);
      
      // Find and tap the delete button for the condition
      final deleteButton = find.byIcon(Icons.delete);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      
      // Assert - condition should be removed
      expect(find.textContaining('test-value'), findsNothing);
      expect(find.text('Add Condition'), findsOneWidget); // Back to initial state
    });
  });
}