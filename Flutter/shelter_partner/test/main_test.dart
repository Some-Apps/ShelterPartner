import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/firebase_service.dart';
import 'package:shelter_partner/helper/debug.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:shelter_partner/main.dart';
import 'package:shelter_partner/views/auth/signup_page.dart';

// Implementing FirebaseService for the test
class MockFirebaseService implements FirebaseService {
  @override
  Future<void> initialize() async {
    return Future<void>.value();
  }
}

void main() {
  final mockUser = MockUser(
    isAnonymous: false,
    email: 'test@example.com',
    displayName: 'Test User',
  );
  final mockAuth = MockFirebaseAuth(mockUser: mockUser);
  final fakeFirestore = FakeFirebaseFirestore();
  final authRepository = AuthRepository(
    firestore: fakeFirestore,
    firebaseAuth: mockAuth,
  );

  group('All Tests', () {
    group('Authentication Tests', () {
      testWidgets('AuthPage is displayed when the app starts', (WidgetTester tester) async {
        await tester.pumpWidget(ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
          ],
          child: MyApp(
            theme: ThemeData.light(),
          ),
        ));

        expect(find.byType(AuthPage), findsOneWidget);
      });
    });

    group("Random", () {
      testWidgets('Create Test Account button is not visible in release mode',
        (WidgetTester tester) async {
        final debugHelper = DebugHelper(debugMode: false);

        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: SignupPage(onTapLogin: () {}, debugHelper: debugHelper),
          ),
        ));

        expect(find.text('Create Test Account'), findsNothing);
      });

      testWidgets('Create Test Account button is visible in debug mode',
          (WidgetTester tester) async {
        final debugHelper = DebugHelper(debugMode: true);

        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: SignupPage(onTapLogin: () {}, debugHelper: debugHelper),
          ),
        ));

        expect(find.text('Create Test Account'), findsOneWidget);
      });
    });
  });
}
