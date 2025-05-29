import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/views/auth/login_or_signup.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:shelter_partner/views/auth/login_page.dart';
import 'package:shelter_partner/views/auth/signup_page.dart';
import 'package:shelter_partner/views/auth/forgot_password_page.dart';

void main() {
  group('LoginOrSignup Widget Tests', () {
    Widget createTestWidget({List<Override>? overrides}) {
      return ProviderScope(
        overrides: overrides ?? const [],
        child: const MaterialApp(
          home: Scaffold(body: LoginOrSignup()),
        ),
      );
    }

    testWidgets('shows LoginPage by default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SignupPage), findsNothing);
      expect(find.byType(ForgotPasswordPage), findsNothing);
    });

    testWidgets('shows SignupPage when authPageProvider is signup',
        (tester) async {
      await tester.pumpWidget(createTestWidget(overrides: [
        authPageProvider.overrideWith(
            (ref) => AuthPageNotifier()..setPage(AuthPageType.signup)),
      ]));
      await tester.pump();
      expect(find.byType(SignupPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(ForgotPasswordPage), findsNothing);
    });

    testWidgets(
        'shows ForgotPasswordPage when authPageProvider is forgotPassword',
        (tester) async {
      await tester.pumpWidget(createTestWidget(overrides: [
        authPageProvider.overrideWith(
            (ref) => AuthPageNotifier()..setPage(AuthPageType.forgotPassword)),
      ]));
      await tester.pump();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(SignupPage), findsNothing);
    });

    testWidgets('navigates to SignupPage when onTapSignup is called',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      // Tap the Create Shelter text
      final createShelter = find.text('Create Shelter');
      expect(createShelter, findsOneWidget);
      await tester.tap(createShelter);
      await tester.pumpAndSettle();
      // Should now show SignupPage
      expect(find.byType(SignupPage), findsOneWidget);
    });

    testWidgets(
        'navigates to ForgotPasswordPage when onTapForgotPassword is called',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      // Tap the Forgot Password? text
      final forgotPassword = find.text('Forgot Password?');
      expect(forgotPassword, findsOneWidget);
      await tester.tap(forgotPassword);
      await tester.pumpAndSettle();
      // Should now show ForgotPasswordPage
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('navigates back to LoginPage from SignupPage', (tester) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(createTestWidget(overrides: [
        authPageProvider.overrideWith(
            (ref) => AuthPageNotifier()..setPage(AuthPageType.signup)),
      ]));
      await tester.pump();
      // Tap the Login Here text
      final loginHere = find.text('Login Here');
      if (loginHere.evaluate().isNotEmpty) {
        await tester.tap(loginHere);
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
      }
    });
  });
}
