import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shelter_partner/views/auth/forgot_password_page.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

import 'forgot_password_page_test.mocks.dart';

@GenerateMocks([AuthViewModel])
void main() {
  testWidgets('ForgotPasswordPage UI and reset flow',
      (WidgetTester tester) async {
    bool loginTapped = false;
    // Set up mock for sendPasswordReset to return a Future<String?>
    final mockAuthViewModel = MockAuthViewModel();
    when(mockAuthViewModel.sendPasswordReset(any))
        .thenAnswer((_) async => null);
    final container = ProviderContainer(overrides: [
      authViewModelProvider.overrideWith((ref) => mockAuthViewModel),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ForgotPasswordPage(
            onTapLogin: () => loginTapped = true,
          ),
        ),
      ),
    );

    // UI elements
    expect(find.text('Reset Password'),
        findsAtLeastNWidgets(2)); // Title (and reset button)
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Reset Password'),
        findsOneWidget); // Button
    expect(find.text('Go Back to Login'), findsOneWidget);

    // Enter email and tap reset
    await tester.enterText(find.byType(TextField), 'test@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump(); // Start dialog
    expect(find.text('Success'), findsOneWidget);
    // Tap OK on success dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tap Go Back to Login
    await tester.tap(find.text('Go Back to Login'));
    expect(loginTapped, isTrue);
  });

  testWidgets('ForgotPasswordPage shows error toast on failure',
      (WidgetTester tester) async {
    // Set up mock for sendPasswordReset to return an error message
    final mockAuthViewModel = MockAuthViewModel();
    when(mockAuthViewModel.sendPasswordReset(any))
        .thenAnswer((_) async => 'Invalid email');
    final container = ProviderContainer(overrides: [
      authViewModelProvider.overrideWith((ref) => mockAuthViewModel),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ForgotPasswordPage(
            onTapLogin: () {},
          ),
        ),
      ),
    );

    // Enter email and tap reset
    await tester.enterText(find.byType(TextField), 'bademail');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await tester.pump(); // Start dialog
    // Since Fluttertoast is a native overlay, we can't check the toast directly in widget tests.
    // Instead, verify that no success dialog appears
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Success'), findsNothing);
  });
}
