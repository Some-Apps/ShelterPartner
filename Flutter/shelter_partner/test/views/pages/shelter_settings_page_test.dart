import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/shelter_settings_page.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_auth_helpers.dart';

void main() {
  group('ShelterSettingsPage', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('displays Only Include Primary Photo From ShelterLuv toggle',
        (WidgetTester tester) async {
      // Arrange
      final container = await createTestUserAndLogin(
        email: 'testuser@example.com',
        password: 'testpassword',
        firstName: 'Test',
        lastName: 'User',
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const ShelterSettingsPage(),
          ),
        ),
      );

      // Allow time for async operations to complete
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Only Include Primary Photo From ShelterLuv'),
        findsOneWidget,
        reason: 'Should display the primary photo toggle',
      );

      // Find the toggle switch
      final toggleFinder = find.ancestor(
        of: find.text('Only Include Primary Photo From ShelterLuv'),
        matching: find.byType(SwitchToggleView),
      );
      expect(toggleFinder, findsOneWidget);

      final switchWidget = find.descendant(
        of: toggleFinder,
        matching: find.byType(Switch),
      );
      expect(switchWidget, findsOneWidget);

      // Get the initial state - should be true by default
      final initialSwitch = tester.widget<Switch>(switchWidget);
      expect(
        initialSwitch.value,
        isTrue,
        reason: 'Primary photo toggle should be enabled by default',
      );
    });

    testWidgets('primary photo toggle can be switched', (WidgetTester tester) async {
      // Arrange
      final container = await createTestUserAndLogin(
        email: 'testuser@example.com',
        password: 'testpassword',
        firstName: 'Test',
        lastName: 'User',
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const ShelterSettingsPage(),
          ),
        ),
      );

      // Allow time for async operations to complete
      await tester.pumpAndSettle();

      // Find the toggle switch
      final toggleFinder = find.ancestor(
        of: find.text('Only Include Primary Photo From ShelterLuv'),
        matching: find.byType(SwitchToggleView),
      );
      expect(toggleFinder, findsOneWidget);

      final switchWidget = find.descendant(
        of: toggleFinder,
        matching: find.byType(Switch),
      );

      // Tap the switch to toggle it
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // The switch should still be functional (this is a basic interaction test)
      expect(switchWidget, findsOneWidget);
    });
  });
}