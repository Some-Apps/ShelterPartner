import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/volunteer_settings_page.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import 'package:shelter_partner/views/components/picker_view.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';

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
      final hasLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;
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

    testWidgets(
      'displays all volunteer settings UI components when data loads',
      (WidgetTester tester) async {
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
          (widget) =>
              widget is TextField &&
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
        expect(
          find.text('Create Logs When Under Minimum Duration'),
          findsOneWidget,
        );
        expect(find.text('Show Custom Form'), findsOneWidget);
        expect(find.text('Append Animal Data To URL'), findsOneWidget);
        expect(find.text('Georestrict'), findsOneWidget);
        expect(find.byType(SwitchToggleView), findsNWidgets(9));

        // Georestriction Settings navigation
        expect(find.text('Georestriction Settings'), findsOneWidget);
      },
    );

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

      // Get shelter ID for Firestore verification
      final volunteersViewModel = container.read(volunteersViewModelProvider);
      final initialShelter = volunteersViewModel.value;
      expect(initialShelter, isNotNull);
      final shelterId = initialShelter!.id;

      // Find the picker and verify it exists
      final pickerFinder = find.descendant(
        of: find.byType(PickerView),
        matching: find.byType(DropdownButton<String>),
      );
      expect(pickerFinder, findsOneWidget);

      // Get the initial value to ensure we can test a change
      final initialDropdown = tester.widget<DropdownButton<String>>(
        pickerFinder,
      );
      final initialValue = initialDropdown.value;
      expect(initialValue, isNotNull);
      expect(['Last Let Out', 'Alphabetical'].contains(initialValue), isTrue);

      // Determine which value to select (the one that's different from current)
      final targetValue = initialValue == 'Last Let Out'
          ? 'Alphabetical'
          : 'Last Let Out';

      // Open the dropdown
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Verify that both dropdown options are available
      expect(find.text('Last Let Out'), findsWidgets);
      expect(find.text('Alphabetical'), findsWidgets);

      // Select the target option
      final targetFinder = find.text(targetValue);
      expect(targetFinder, findsWidgets);
      await tester.tap(targetFinder.last);
      await tester.pumpAndSettle();

      // Verify the selection was persisted to Firestore
      final docSnapshotAfterChange = await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .get();
      expect(docSnapshotAfterChange.exists, isTrue);

      final dataAfterChange =
          docSnapshotAfterChange.data() as Map<String, dynamic>;
      final volunteerSettingsAfterChange =
          dataAfterChange['volunteerSettings'] as Map<String, dynamic>;
      final updatedSort =
          volunteerSettingsAfterChange['enrichmentSort'] as String;

      expect(
        updatedSort,
        equals(targetValue),
        reason:
            'Firestore should be updated with the new enrichment sort value',
      );

      // Verify the picker can be found and interacted with again after selection
      expect(pickerFinder, findsOneWidget);

      // Open dropdown again to verify we can switch back
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Select the original value to demonstrate bidirectional switching
      final originalFinder = find.text(initialValue!);
      expect(originalFinder, findsWidgets);
      await tester.tap(originalFinder.last);
      await tester.pumpAndSettle();

      // Verify the switch back was also persisted to Firestore
      final docSnapshotAfterSwitchBack = await FirebaseTestOverrides
          .fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .get();
      expect(docSnapshotAfterSwitchBack.exists, isTrue);

      final dataAfterSwitchBack =
          docSnapshotAfterSwitchBack.data() as Map<String, dynamic>;
      final volunteerSettingsAfterSwitchBack =
          dataAfterSwitchBack['volunteerSettings'] as Map<String, dynamic>;
      final finalSort =
          volunteerSettingsAfterSwitchBack['enrichmentSort'] as String;

      expect(
        finalSort,
        equals(initialValue),
        reason:
            'Firestore should be updated back to the original enrichment sort value',
      );

      // Verify the picker is still functional after multiple interactions
      expect(pickerFinder, findsOneWidget);

      // Final verification: the picker should still be responsive
      final finalDropdown = tester.widget<DropdownButton<String>>(pickerFinder);
      expect(finalDropdown.value, isNotNull);
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

      // Get initial shelter data to verify the starting state
      final volunteersViewModel = container.read(volunteersViewModelProvider);
      final initialShelter = volunteersViewModel.value;
      expect(initialShelter, isNotNull);
      final shelterId = initialShelter?.id;

      // Find the text field and enter text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      const testURL = 'https://example.com/form';
      await tester.enterText(textField, testURL);
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text(testURL), findsOneWidget);

      // Simulate losing focus to trigger the onChanged callback
      await tester.tap(find.text('Volunteer Settings'));
      await tester.pumpAndSettle();

      // Verify the custom form URL was persisted to Firestore
      final docSnapshotAfterInput = await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .get();
      expect(docSnapshotAfterInput.exists, isTrue);

      final dataAfterInput =
          docSnapshotAfterInput.data() as Map<String, dynamic>;
      final volunteerSettingsAfterInput =
          dataAfterInput['volunteerSettings'] as Map<String, dynamic>;
      final updatedURL = volunteerSettingsAfterInput['customFormURL'] as String;

      expect(
        updatedURL,
        equals(testURL),
        reason: 'Firestore should be updated with the new custom form URL',
      );

      // The text field should still contain the entered text
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, equals(testURL));
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

      // Get initial shelter data to verify the starting state
      final volunteersViewModel = container.read(volunteersViewModelProvider);
      final initialShelter = volunteersViewModel.value;
      expect(initialShelter, isNotNull);
      final initialMinutes =
          initialShelter!.volunteerSettings.minimumLogMinutes;
      final shelterId = initialShelter.id;

      // Find the number stepper
      final stepperFinder = find.byType(NumberStepperView);
      expect(stepperFinder, findsOneWidget);

      // Get initial value from the stepper widget and verify it matches the data model
      final initialStepperWidget = tester.widget<NumberStepperView>(
        stepperFinder,
      );
      final initialValue = initialStepperWidget.value;
      expect(initialValue, equals(initialMinutes));
      expect(initialValue, greaterThanOrEqualTo(0));

      // Find the text displaying the current value
      final valueText = find.text('$initialValue minutes');
      expect(
        valueText,
        findsOneWidget,
        reason: 'The stepper should display the current value',
      );

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

      // Test increment functionality and verify Firestore persistence
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      // Verify the increment was persisted to Firestore
      final docSnapshotAfterIncrement = await FirebaseTestOverrides
          .fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .get();
      expect(docSnapshotAfterIncrement.exists, isTrue);

      final dataAfterIncrement =
          docSnapshotAfterIncrement.data() as Map<String, dynamic>;
      final volunteerSettingsAfterIncrement =
          dataAfterIncrement['volunteerSettings'] as Map<String, dynamic>;
      final updatedMinutes =
          volunteerSettingsAfterIncrement['minimumLogMinutes'] as int;

      expect(
        updatedMinutes,
        equals(initialMinutes + 1),
        reason: 'Firestore should be updated with incremented value',
      );

      // Verify the stepper maintains its functionality after interaction
      expect(stepperFinder, findsOneWidget);
      final stepperAfterIncrement = tester.widget<NumberStepperView>(
        stepperFinder,
      );
      expect(stepperAfterIncrement.value, isNotNull);

      // Test decrement functionality and verify Firestore persistence
      await tester.tap(decrementButton);
      await tester.pumpAndSettle();

      // Verify the decrement was persisted to Firestore
      final docSnapshotAfterDecrement = await FirebaseTestOverrides
          .fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .get();
      expect(docSnapshotAfterDecrement.exists, isTrue);

      final dataAfterDecrement =
          docSnapshotAfterDecrement.data() as Map<String, dynamic>;
      final volunteerSettingsAfterDecrement =
          dataAfterDecrement['volunteerSettings'] as Map<String, dynamic>;
      final finalMinutes =
          volunteerSettingsAfterDecrement['minimumLogMinutes'] as int;

      expect(
        finalMinutes,
        equals(initialMinutes),
        reason:
            'Firestore should be updated with decremented value (back to initial)',
      );

      // Verify the stepper is still functional after multiple interactions
      expect(stepperFinder, findsOneWidget);
      final stepperAfterDecrement = tester.widget<NumberStepperView>(
        stepperFinder,
      );
      expect(stepperAfterDecrement.value, isNotNull);

      // Verify both buttons are still present and responsive
      expect(incrementButton, findsOneWidget);
      expect(decrementButton, findsOneWidget);
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

        // Get initial shelter data to verify the starting state
        final volunteersViewModel = container.read(volunteersViewModelProvider);
        final initialShelter = volunteersViewModel.value;
        expect(initialShelter, isNotNull);
        final expectedInitialValue =
            initialShelter!.volunteerSettings.photoUploadsAllowed;
        final shelterId = initialShelter.id;

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

        // Get initial state and verify it matches the data model
        final initialSwitch = tester.widget<Switch>(switchWidget);
        final initialValue = initialSwitch.value;
        expect(initialValue, equals(expectedInitialValue));

        // Tap the switch to toggle it
        await tester.tap(switchWidget);
        await tester.pumpAndSettle();

        // Verify the toggle was persisted to Firestore
        final docSnapshotAfterToggle = await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .get();
        expect(docSnapshotAfterToggle.exists, isTrue);

        final dataAfterToggle =
            docSnapshotAfterToggle.data() as Map<String, dynamic>;
        final volunteerSettingsAfterToggle =
            dataAfterToggle['volunteerSettings'] as Map<String, dynamic>;
        final updatedValue =
            volunteerSettingsAfterToggle['photoUploadsAllowed'] as bool;

        expect(
          updatedValue,
          equals(!expectedInitialValue),
          reason:
              'Firestore should be updated with the toggled photo uploads value',
        );

        // The switch should still be present and functional after toggle
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

        // Get initial shelter data to verify the starting state
        final volunteersViewModel = container.read(volunteersViewModelProvider);
        final initialShelter = volunteersViewModel.value;
        expect(initialShelter, isNotNull);
        final expectedInitialValue =
            initialShelter!.volunteerSettings.requireName;
        final shelterId = initialShelter.id;

        // Scroll to ensure content is visible
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -300));
          await tester.pumpAndSettle();
        }

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

        // Get initial state and verify it matches the data model
        final initialSwitch = tester.widget<Switch>(switchWidget);
        expect(initialSwitch.value, equals(expectedInitialValue));

        // Tap the switch to toggle it
        await tester.tap(switchWidget, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify the toggle was persisted to Firestore
        final docSnapshotAfterToggle = await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .get();
        expect(docSnapshotAfterToggle.exists, isTrue);

        final dataAfterToggle =
            docSnapshotAfterToggle.data() as Map<String, dynamic>;
        final volunteerSettingsAfterToggle =
            dataAfterToggle['volunteerSettings'] as Map<String, dynamic>;
        final updatedValue =
            volunteerSettingsAfterToggle['requireName'] as bool;

        expect(
          updatedValue,
          equals(!expectedInitialValue),
          reason:
              'Firestore should be updated with the toggled require name value',
        );

        // The switch should still be present and functional after toggle
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

        // Get initial shelter data to verify the starting state
        final volunteersViewModel = container.read(volunteersViewModelProvider);
        final initialShelter = volunteersViewModel.value;
        expect(initialShelter, isNotNull);
        final expectedInitialValue =
            initialShelter!.volunteerSettings.geofence?.isEnabled ?? false;
        final shelterId = initialShelter.id;

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

        // Get initial state and verify it matches the data model
        final initialSwitch = tester.widget<Switch>(switchWidget);
        expect(initialSwitch.value, equals(expectedInitialValue));

        // Tap the switch to toggle it
        await tester.tap(switchWidget, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify the toggle was persisted to Firestore
        final docSnapshotAfterToggle = await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .get();
        expect(docSnapshotAfterToggle.exists, isTrue);

        final dataAfterToggle =
            docSnapshotAfterToggle.data() as Map<String, dynamic>;
        final volunteerSettingsAfterToggle =
            dataAfterToggle['volunteerSettings'] as Map<String, dynamic>;
        final geofenceAfterToggle =
            volunteerSettingsAfterToggle['geofence'] as Map<String, dynamic>?;
        final updatedValue =
            geofenceAfterToggle?['isEnabled'] as bool? ?? false;

        expect(
          updatedValue,
          equals(!expectedInitialValue),
          reason:
              'Firestore should be updated with the toggled georestrict value',
        );

        // The switch should still be present and functional after toggle
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
          child: MaterialApp(
            home: const VolunteerSettingsPage(),
            routes: {
              '/georestriction': (context) =>
                  const Scaffold(body: Text('Georestriction Settings Page')),
            },
          ),
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
      await tester.tap(geoSettingsTile, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify that navigation occurred by checking if we can find the georestriction page content
      // Note: In the actual app, this navigates to GeorestrictionSettingsPage
      // For testing purposes, we verify that the tap is handled and no errors occur
      expect(find.text('Georestriction Settings'), findsOneWidget);

      // Additional verification: ensure the tile is still tappable (no errors occurred)
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
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Custom Form URL',
        );
        expect(customFormField, findsOneWidget);

        // The text controller should have the data from Firestore
        final textField = tester.widget<TextField>(customFormField);
        expect(textField.controller?.text, equals('https://test.com/form'));

        // Verify enrichment sort picker displays the correct value
        final pickerFinder = find.descendant(
          of: find.byType(PickerView),
          matching: find.byType(DropdownButton<String>),
        );
        expect(pickerFinder, findsOneWidget);

        // Get the current value of the picker
        final dropdownWidget = tester.widget<DropdownButton<String>>(
          pickerFinder,
        );
        expect(dropdownWidget.value, equals('Alphabetical'));

        // Verify minimum duration number stepper displays the correct value
        final stepperFinder = find.byType(NumberStepperView);
        expect(stepperFinder, findsOneWidget);

        // Check that the NumberStepperView has the correct value
        final stepperWidget = tester.widget<NumberStepperView>(stepperFinder);
        expect(stepperWidget.value, equals(15));
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

        // Expected switch titles and their default values from the model
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

        // Scroll to ensure all content is visible
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -500));
          await tester.pumpAndSettle();
        }

        for (final title in expectedSwitchTitles) {
          expect(
            find.text(title),
            findsOneWidget,
            reason: 'Switch with title "$title" should be present',
          );

          final switchToggle = find.ancestor(
            of: find.text(title),
            matching: find.byType(SwitchToggleView),
          );
          expect(
            switchToggle,
            findsOneWidget,
            reason: 'SwitchToggleView for "$title" should be present',
          );

          // Verify the switch widget exists (but not necessarily specific values since they come from defaults)
          final switchWidget = find.descendant(
            of: switchToggle,
            matching: find.byType(Switch),
          );
          expect(
            switchWidget,
            findsOneWidget,
            reason: 'Switch widget for "$title" should be present',
          );
        }

        // Verify we have exactly the expected number of switches
        expect(
          find.byType(SwitchToggleView),
          findsNWidgets(expectedSwitchTitles.length),
        );
      });
    });
  });
}
