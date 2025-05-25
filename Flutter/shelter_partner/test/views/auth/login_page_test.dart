import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelter_partner/views/auth/login_page.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/auth/my_textfield.dart';

@GenerateMocks([AuthRepository, UserCredential, User])
import 'login_page_test.mocks.dart';

void main() {
  group('LoginPage Widget Tests', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      when(mockAuthRepository.signInWithEmailAndPassword(any, any))
          .thenAnswer((_) async {
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUserCredential.user).thenReturn(mockUser);
        return mockUserCredential;
      });

      when(mockAuthRepository.getUserById(any)).thenAnswer((_) async => null);
    });

    tearDown(() {
      reset(mockAuthRepository);
    });

    Widget createTestWidget({List<Override>? providerOverrides}) {
      return ProviderScope(
        overrides: providerOverrides ??
            [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      );
    }

    void setupTestViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Finder emailField() => find.byWidgetPredicate(
          (Widget widget) =>
              widget is MyTextField && widget.hintText == 'Email',
        );

    Finder passwordField() => find.byWidgetPredicate(
          (Widget widget) =>
              widget is MyTextField && widget.hintText == 'Password',
        );

    Finder loginButton() => find.widgetWithText(ElevatedButton, 'Log In');
    testWidgets('should display all UI elements correctly',
        (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(emailField(), findsOneWidget);
      expect(passwordField(), findsOneWidget);
      expect(loginButton(), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Shelter'), findsOneWidget);
    });
    testWidgets(
        'should call signInWithEmailAndPassword when login button tapped',
        (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'mypassword');
      await tester.tap(loginButton());
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthRepository.signInWithEmailAndPassword(
              'user@example.com', 'mypassword'))
          .called(1);
    });

    testWidgets('should call onTapForgotPassword when forgot password tapped',
        (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);
      var tapped = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          providerOverrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository)
          ],
          child: MaterialApp(
            home: LoginPage(onTapForgotPassword: () => tapped = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should call onTapSignup when create shelter tapped',
        (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);
      var tapped = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository)
          ],
          child: MaterialApp(
            home: LoginPage(onTapSignup: () => tapped = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Shelter'));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });
    testWidgets('should trigger login when enter pressed in email field',
        (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'mypassword');
      await tester.tap(emailField());
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthRepository.signInWithEmailAndPassword(
              'user@example.com', 'mypassword'))
          .called(1);
    });
    testWidgets('should trigger login when enter pressed in password field',
        (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'mypassword');
      await tester.tap(passwordField());
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthRepository.signInWithEmailAndPassword(
              'user@example.com', 'mypassword'))
          .called(1);
    });
  });
}
