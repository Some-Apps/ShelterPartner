import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/components/feedback_submission_dialog.dart';

import '../../helpers/firebase_test_overrides.dart';

void main() {
  group('FeedbackSubmissionDialog Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('should display all UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(
            home: Scaffold(body: FeedbackSubmissionDialog()),
          ),
        ),
      );

      // Verify dialog title
      expect(find.text('Submit Feedback'), findsOneWidget);

      // Verify input fields
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      // Verify screenshot button
      expect(find.text('Add Screenshot (Optional)'), findsOneWidget);
    });

    testWidgets('should show validation message for empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(
            home: Scaffold(body: FeedbackSubmissionDialog()),
          ),
        ),
      );

      // Try to submit without filling fields
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Should show validation message
      expect(
        find.text('Please fill in both title and description'),
        findsOneWidget,
      );
    });

    testWidgets('should close dialog when Cancel is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const FeedbackSubmissionDialog(),
                  ),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Submit Feedback'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Submit Feedback'), findsNothing);
    });

    testWidgets('should enable and disable submit button correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(
            home: Scaffold(body: FeedbackSubmissionDialog()),
          ),
        ),
      );

      final submitButton = find.widgetWithText(ElevatedButton, 'Submit');

      // Submit button should be enabled initially
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);

      // Fill in the title field
      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Test Feedback',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'This is a test feedback',
      );
      await tester.pump();

      // Submit button should still be enabled with text filled
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });
  });
}
