import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shelter_partner/views/auth/login_page.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import '../helpers/firebase_test_overrides.dart';
import '../helpers/mock_file_loader.dart';

void main() {
  group('LoginPage Golden Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    Future<Widget> createTestWidget() async {
      return ProviderScope(
        overrides: [
          ...FirebaseTestOverrides.overrides,
          authRepositoryProvider.overrideWith((ref) {
            final firestore = ref.watch(firestoreProvider);
            final firebaseAuth = ref.watch(firebaseAuthProvider);
            return AuthRepository(
              firestore: firestore,
              firebaseAuth: firebaseAuth,
              fileLoader: MockFileLoader(),
            );
          }),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      );
    }

    void setupTestViewport(WidgetTester tester) {
      // Set a consistent viewport size for screenshots
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('login page appears correctly', (WidgetTester tester) async {
      // Arrange
      setupTestViewport(tester);
      final widget = await createTestWidget();

      // Act
      await tester.pumpWidget(widget);
      
      // Multiple pumps to handle the FutureBuilder and image loading
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('login_page.png'),
      );
    }, tags: ['golden']);
  });
}