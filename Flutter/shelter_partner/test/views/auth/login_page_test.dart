import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:shelter_partner/services/mock_logger_service.dart';

import 'package:shelter_partner/views/auth/login_page.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/auth/my_textfield.dart';
import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/mock_file_loader.dart';

void main() {
  group('LoginPage Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    Future<({Widget widget, ProviderContainer container})> createTestWidget(
      WidgetTester tester,
    ) async {
      final key = GlobalKey();
      final widget = ProviderScope(
        overrides: [
          ...FirebaseTestOverrides.overrides,
          authRepositoryProvider.overrideWith((ref) {
            final firestore = ref.watch(firestoreProvider);
            final firebaseAuth = ref.watch(firebaseAuthProvider);
            return AuthRepository(
              firestore: firestore,
              firebaseAuth: firebaseAuth,
              fileLoader: MockFileLoader(),
              logger: MockLoggerService(),
            );
          }),
        ],
        child: MaterialApp(home: LoginPage(key: key)),
      );
      await tester.pumpWidget(widget);
      await tester.pump(); // Ensure widget is mounted
      final context = key.currentContext!;
      final container = ProviderScope.containerOf(context);
      return (widget: widget, container: container);
    }

    void setupTestViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Finder emailField() => find.byWidgetPredicate(
      (Widget widget) => widget is MyTextField && widget.hintText == 'Email',
    );

    Finder passwordField() => find.byWidgetPredicate(
      (Widget widget) => widget is MyTextField && widget.hintText == 'Password',
    );

    Finder loginButton() => find.widgetWithText(ElevatedButton, 'Log In');

    testWidgets('should display all UI elements correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      setupTestViewport(tester);
      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc('test-uid')
          .set({
            'firstName': 'Test',
            'lastName': 'User',
            'email': 'user@example.com',
          });
      await createTestWidget(tester);
      // Assert
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(emailField(), findsOneWidget);
      expect(passwordField(), findsOneWidget);
      expect(loginButton(), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Shelter'), findsOneWidget);
    });

    testWidgets('should authenticate user when login button tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      setupTestViewport(tester);
      final container = (await createTestWidget(tester)).container;
      final authViewModel = container.read(authViewModelProvider.notifier);
      await authViewModel.signup(
        email: 'tapSignup@example.com',
        password: 'mypassword',
        firstName: 'Test',
        lastName: 'User',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      // Act
      await tester.enterText(emailField(), 'tapSignup@example.com');
      await tester.enterText(passwordField(), 'mypassword');
      await tester.pump(); // Allow text to update
      await tester.tap(loginButton());
      await tester.pump(); // Allow tap to register
      // Assert
      final authState = container.read(authViewModelProvider);
      expect(
        authState.status,
        AuthStatus.authenticated,
        reason: 'User should be authenticated after login',
      );
    });

    testWidgets('should call onTapForgotPassword when forgot password tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      setupTestViewport(tester);
      var tapped = false;
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: MaterialApp(
            home: LoginPage(onTapForgotPassword: () => tapped = true),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();
      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should call onTapSignup when create shelter tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      setupTestViewport(tester);
      var tapped = false;
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: MaterialApp(home: LoginPage(onTapSignup: () => tapped = true)),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Create Shelter'));
      await tester.pump();
      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should authenticate user when enter pressed in email field', (
      WidgetTester tester,
    ) async {
      // Arrange
      setupTestViewport(tester);
      final container = (await createTestWidget(tester)).container;
      final authViewModel = container.read(authViewModelProvider.notifier);
      await authViewModel.signup(
        email: 'enterInEmailField@example.com',
        password: 'mypassword',
        firstName: 'Test',
        lastName: 'User',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      // Act
      await tester.enterText(emailField(), 'enterInEmailField@example.com');
      await tester.enterText(passwordField(), 'mypassword');
      await tester.pump(); // Allow text to update
      await tester.tap(emailField());
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      // Assert
      final authState = container.read(authViewModelProvider);
      expect(
        authState.status,
        AuthStatus.authenticated,
        reason: 'User should be authenticated after login',
      );
    });

    testWidgets(
      'should authenticate user when enter pressed in password field',
      (WidgetTester tester) async {
        // Arrange
        setupTestViewport(tester);
        final container = (await createTestWidget(tester)).container;
        final authViewModel = container.read(authViewModelProvider.notifier);
        await authViewModel.signup(
          email: 'enterInPasswordField@example.com',
          password: 'mypassword',
          firstName: 'Test',
          lastName: 'User',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
        // Act
        await tester.enterText(
          emailField(),
          'enterInPasswordField@example.com',
        );
        await tester.enterText(passwordField(), 'mypassword');
        await tester.tap(passwordField());
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        // Assert
        final authState = container.read(authViewModelProvider);
        expect(
          authState.status,
          AuthStatus.authenticated,
          reason: 'User should be authenticated after login',
        );
      },
    );
  });
}
