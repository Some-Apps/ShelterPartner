import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'firebase_test_overrides.dart';
import 'mock_file_loader.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

/// Helper to create a test user and shelter using the real signup flow.
/// Returns the ProviderContainer for further use in tests.
Future<ProviderContainer> createTestUserAndLogin({
  String email = 'testuser@example.com',
  String password = 'testpassword',
  String firstName = 'Test',
  String lastName = 'User',
  String shelterName = 'Test Shelter',
  String shelterAddress = '123 Test St',
  String selectedManagementSoftware = 'ShelterLuv',
}) async {
  final container = ProviderContainer(
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
  );
  final authViewModel = container.read(authViewModelProvider.notifier);
  await authViewModel.signup(
    email: email,
    password: password,
    firstName: firstName,
    lastName: lastName,
    shelterName: shelterName,
    shelterAddress: shelterAddress,
    selectedManagementSoftware: selectedManagementSoftware,
  );
  return container;
}
