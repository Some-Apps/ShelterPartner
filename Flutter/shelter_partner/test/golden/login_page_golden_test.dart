@Tags(['golden'])
library login_page_golden_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:shelter_partner/views/auth/login_page.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import '../helpers/firebase_test_overrides.dart';
import '../helpers/mock_file_loader.dart';

void main() {
  testGoldens('LoginPage Golden Tests', (WidgetTester tester) async {
    FirebaseTestOverrides.initialize();
    await loadAppFonts();

    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: [
          ...FirebaseTestOverrides.overrides,
          authRepositoryProvider.overrideWith((ref) {
            final firestore = ref.watch(firestoreProvider);
            final firebaseAuth = ref.watch(firebaseAuthProvider);
            final logger = ref.watch(loggerServiceProvider);
            return AuthRepository(
              firestore: firestore,
              firebaseAuth: firebaseAuth,
              logger: logger,
              fileLoader: MockFileLoader(),
            );
          }),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
      surfaceSize: const Size(1600, 1200),
    );
    await screenMatchesGolden(tester, 'login_page');
  });
}
