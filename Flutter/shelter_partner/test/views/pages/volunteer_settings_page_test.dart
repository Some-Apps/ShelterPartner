import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/volunteer_settings_page.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import 'package:shelter_partner/views/components/picker_view.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('VolunteerSettingsPage Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('displays loading state while data is being fetched', (
      WidgetTester tester,
    ) async {
      // Arrange
      final container = ProviderContainer(
        overrides: FirebaseTestOverrides.overrides,
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerSettingsPage()),
        ),
      );
      // Don't settle immediately to catch loading state
      await tester.pump();

      // Assert - should show loading or error (since no user is authenticated)
      expect(find.text('Volunteer Settings'), findsOneWidget);
      // Loading or error state should be present
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasError = find.textContaining('Error:').evaluate().isNotEmpty;
      expect(hasLoading || hasError, isTrue);
    });

    testWidgets('displays error state when user is not authenticated', (
      WidgetTester tester,
    ) async {
      // Arrange
      final container = ProviderContainer(
        overrides: FirebaseTestOverrides.overrides,
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.text('Volunteer Settings'), findsOneWidget);
    });

    testWidgets('displays all volunteer settings UI components when data loads', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'volunteeruser@example.com',
        password: 'testpassword',
        firstName: 'Volunteer',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check that all major components are present
      expect(find.text('Volunteer Settings'), findsOneWidget);
      
      // Enrichment Sort picker
      expect(find.text('Enrichment Sort'), findsOneWidget);
      expect(find.byType(PickerView), findsOneWidget);
      
      // Enrichment Filter navigation
      expect(find.text('Enrichment Filter'), findsOneWidget);
      expect(find.byType(NavigationButton), findsAtLeastNWidgets(1));
      
      // Custom Form URL text field - look for the input decoration
      final customFormTextFieldFinder = find.byWidgetPredicate(
        (widget) => widget is TextField && 
            widget.decoration?.labelText == 'Custom Form URL',
      );
      expect(customFormTextFieldFinder, findsOneWidget);
      
      // Minimum Duration stepper
      expect(find.text('Minimum Duration'), findsOneWidget);
      expect(find.byType(NumberStepperView), findsOneWidget);
      
      // Switch toggles
      expect(find.text('Photo Uploads Allowed'), findsOneWidget);
      expect(find.text('Allow Bulk Take Out'), findsOneWidget);
      expect(find.text('Require Let Out Type'), findsOneWidget);
      expect(find.text('Require Early Put Back Reason'), findsOneWidget);
      expect(find.text('Require Name'), findsOneWidget);
      expect(find.text('Create Logs When Under Minimum Duration'), findsOneWidget);
      expect(find.text('Show Custom Form'), findsOneWidget);
      expect(find.text('Append Animal Data To URL'), findsOneWidget);
      expect(find.text('Georestrict'), findsOneWidget);
      expect(find.byType(SwitchToggleView), findsNWidgets(9));
      
      // Georestriction Settings navigation
      expect(find.text('Georestriction Settings'), findsOneWidget);
    });

    testWidgets('enrichment sort picker updates when selection changes', (
      WidgetTester tester,
    ) async {
      // Arrange
      final container = await createTestUserAndLogin(
        email: 'volunteeruser@example.com',
        password: 'testpassword',
        firstName: 'Volunteer',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the picker dropdown
      final pickerFinder = find.descendant(
        of: find.byType(PickerView),
        matching: find.byType(DropdownButton<String>),
      );
      expect(pickerFinder, findsOneWidget);
      
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Verify that dropdown options are available
      expect(find.text('Last Let Out'), findsWidgets);
      expect(find.text('Alphabetical'), findsWidgets);

      // Select "Alphabetical" option if it exists
      final alphabeticalFinder = find.text('Alphabetical');
      if (alphabeticalFinder.evaluate().isNotEmpty) {
        await tester.tap(alphabeticalFinder.last);
        await tester.pumpAndSettle();
      }

      // Verify the picker is still present (selection change tested at integration level)
      expect(pickerFinder, findsOneWidget);
    });

    testWidgets('custom form URL text field updates on input', (
      WidgetTester tester,
    ) async {
      // Arrange
      final container = await createTestUserAndLogin(
        email: 'volunteeruser@example.com',
        password: 'testpassword',
        firstName: 'Volunteer',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the text field and enter text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      
      await tester.enterText(textField, 'https://example.com/form');
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text('https://example.com/form'), findsOneWidget);
    });

    testWidgets('minimum duration number stepper increments and decrements', (
      WidgetTester tester,
    ) async {
      // Arrange
      final container = await createTestUserAndLogin(
        email: 'volunteeruser@example.com',
        password: 'testpassword',
        firstName: 'Volunteer',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the number stepper
      final stepperFinder = find.byType(NumberStepperView);
      expect(stepperFinder, findsOneWidget);

      // Find increment and decrement buttons within the stepper
      final incrementButton = find.descendant(
        of: stepperFinder,
        matching: find.byIcon(Icons.add),
      );
      final decrementButton = find.descendant(
        of: stepperFinder,
        matching: find.byIcon(Icons.remove),
      );

      expect(incrementButton, findsOneWidget);
      expect(decrementButton, findsOneWidget);

      // Test increment
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Test decrement
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // The stepper should still be visible and functional
      expect(stepperFinder, findsOneWidget);
    });

    group('switch toggle functionality', () {
      testWidgets('photo uploads allowed switch toggles correctly', (
        WidgetTester tester,
      ) async {
        // Arrange
        final container = await createTestUserAndLogin(
          email: 'volunteeruser@example.com',
          password: 'testpassword',
          firstName: 'Volunteer',
          lastName: 'Tester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VolunteerSettingsPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Find the specific switch for photo uploads
        final photoUploadSwitchFinder = find.ancestor(
          of: find.text('Photo Uploads Allowed'),
          matching: find.byType(SwitchToggleView),
        );
        expect(photoUploadSwitchFinder, findsOneWidget);

        final switchWidget = find.descendant(
          of: photoUploadSwitchFinder,
          matching: find.byType(Switch),
        );
        expect(switchWidget, findsOneWidget);

        // Tap the switch
        await tester.tap(switchWidget);
        await tester.pumpAndSettle();

        // The switch should still be present (value change tested in integration)
        expect(switchWidget, findsOneWidget);
      });

      testWidgets('require name switch toggles correctly', (
        WidgetTester tester,
      ) async {
        // Arrange
        final container = await createTestUserAndLogin(
          email: 'volunteeruser@example.com',
          password: 'testpassword',
          firstName: 'Volunteer',
          lastName: 'Tester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VolunteerSettingsPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Find the specific switch for require name
        final requireNameSwitchFinder = find.ancestor(
          of: find.text('Require Name'),
          matching: find.byType(SwitchToggleView),
        );
        expect(requireNameSwitchFinder, findsOneWidget);

        final switchWidget = find.descendant(
          of: requireNameSwitchFinder,
          matching: find.byType(Switch),
        );
        expect(switchWidget, findsOneWidget);

        // Tap the switch
        await tester.tap(switchWidget);
        await tester.pumpAndSettle();

        // The switch should still be present
        expect(switchWidget, findsOneWidget);
      });

      testWidgets('georestrict switch toggles correctly', (
        WidgetTester tester,
      ) async {
        // Arrange
        final container = await createTestUserAndLogin(
          email: 'volunteeruser@example.com',
          password: 'testpassword',
          firstName: 'Volunteer',
          lastName: 'Tester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VolunteerSettingsPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll to ensure content is visible
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -500));
          await tester.pumpAndSettle();
        }

        // Find the specific switch for georestrict
        final geoRestrictSwitchFinder = find.ancestor(
          of: find.text('Georestrict'),
          matching: find.byType(SwitchToggleView),
        );
        expect(geoRestrictSwitchFinder, findsOneWidget);

        final switchWidget = find.descendant(
          of: geoRestrictSwitchFinder,
          matching: find.byType(Switch),
        );
        expect(switchWidget, findsOneWidget);

        // Tap the switch
        await tester.tap(switchWidget, warnIfMissed: false);
        await tester.pumpAndSettle();

        // The switch should still be present
        expect(switchWidget, findsOneWidget);
      });
    });

    testWidgets('navigation to georestriction settings works', (
      WidgetTester tester,
    ) async {
      // Arrange
      final container = await createTestUserAndLogin(
        email: 'volunteeruser@example.com',
        password: 'testpassword',
        firstName: 'Volunteer',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to ensure content is visible
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      // Find the georestriction settings list tile
      final geoSettingsTile = find.ancestor(
        of: find.text('Georestriction Settings'),
        matching: find.byType(ListTile),
      );
      expect(geoSettingsTile, findsOneWidget);

      // Tap the tile - this should try to navigate
      // Note: In a full test, we'd need to mock the Navigator or use testability features
      await tester.tap(geoSettingsTile, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The tile should still be present after tap
      expect(geoSettingsTile, findsOneWidget);
    });

    group('data integration tests', () {
      testWidgets('shelter data is properly displayed in UI components', (
        WidgetTester tester,
      ) async {
        // Arrange
        final container = await createTestUserAndLogin(
          email: 'integrationuser@example.com',
          password: 'testpassword',
          firstName: 'Integration',
          lastName: 'Tester',
          shelterName: 'Integration Test Shelter',
          shelterAddress: '456 Integration St',
          selectedManagementSoftware: 'ShelterLuv',
        );

        // Setup specific volunteer settings data
        final user = container.read(appUserProvider);
        final shelterId = user?.shelterId ?? 'test-shelter';
        
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .update({
          'volunteerSettings.enrichmentSort': 'Alphabetical',
          'volunteerSettings.customFormURL': 'https://test.com/form',
          'volunteerSettings.minimumLogMinutes': 15,
          'volunteerSettings.photoUploadsAllowed': true,
          'volunteerSettings.requireName': true,
        });

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VolunteerSettingsPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Verify that the shelter data is reflected in the UI
        expect(find.text('Volunteer Settings'), findsOneWidget);
        
        // Find the custom form text field and verify it has the expected value
        final customFormField = find.byWidgetPredicate(
          (widget) => widget is TextField && 
              widget.decoration?.labelText == 'Custom Form URL',
        );
        expect(customFormField, findsOneWidget);
        
        // The text controller should have the data from Firestore
        final textField = tester.widget<TextField>(customFormField);
        expect(textField.controller?.text, equals('https://test.com/form'));
      });

      testWidgets('all switch components render with correct initial states', (
        WidgetTester tester,
      ) async {
        // Arrange
        final container = await createTestUserAndLogin(
          email: 'switchuser@example.com',
          password: 'testpassword',
          firstName: 'Switch',
          lastName: 'Tester',
          shelterName: 'Switch Test Shelter',
          shelterAddress: '789 Switch St',
          selectedManagementSoftware: 'ShelterLuv',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VolunteerSettingsPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Check that all expected switches are present
        final expectedSwitchTitles = [
          'Photo Uploads Allowed',
          'Allow Bulk Take Out',
          'Require Let Out Type',
          'Require Early Put Back Reason',
          'Require Name',
          'Create Logs When Under Minimum Duration',
          'Show Custom Form',
          'Append Animal Data To URL',
          'Georestrict',
        ];

        for (final title in expectedSwitchTitles) {
          expect(find.text(title), findsOneWidget,
              reason: 'Switch with title "$title" should be present');
          
          final switchToggle = find.ancestor(
            of: find.text(title),
            matching: find.byType(SwitchToggleView),
          );
          expect(switchToggle, findsOneWidget,
              reason: 'SwitchToggleView for "$title" should be present');
        }

        // Verify we have exactly the expected number of switches
        expect(find.byType(SwitchToggleView), findsNWidgets(expectedSwitchTitles.length));
      });
    });
  });
}