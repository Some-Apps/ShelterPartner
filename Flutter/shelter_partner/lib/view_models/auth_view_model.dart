import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthViewModel(authRepository);
});

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) : super(AuthState.loading()) {
    _checkAuthStatus(); // Check auth status when initializing
  }

  // Method to check current auth status
  Future<void> _checkAuthStatus() async {
    try {
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        final appUser = await _authRepository.getUserById(user.uid);
        if (appUser != null) {
          state = AuthState.authenticated(appUser);
        } else {
          state = AuthState.unauthenticated();
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

 void resetState() {
    state = AuthState.unauthenticated();
  }
  // Login method
  Future<void> login(String email, String password) async {
  state = AuthState.loading(message: "Logging in...");
    try {
      final userCredential = await _authRepository.signInWithEmailAndPassword(email, password);
      final appUser = await _authRepository.getUserById(userCredential.user!.uid);
      if (appUser != null) {
        state = AuthState.authenticated(appUser);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

    Future<String?> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return null; // Success, no error message
    } catch (e) {
      return e.toString(); // Return error message if there's an issue
    }
  }

  // Signup method
  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String shelterName,
    required String shelterAddress,
    required String selectedManagementSoftware,
  }) async {
  state = AuthState.loading(message: "Creating Shelter...");
    try {
      final userCredential = await _authRepository.signUpWithEmailAndPassword(email, password);
      String uid = userCredential.user!.uid;
      String shelterId = const Uuid().v4();

      // Create user and shelter documents in Firestore
      await _authRepository.createUserDocument(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        shelterId: shelterId,
        email: email,
        selectedManagementSoftware: selectedManagementSoftware,
        shelterName: shelterName,
        shelterAddress: shelterAddress,
      );

      final appUser = await _authRepository.getUserById(uid);
      if (appUser != null) {
        state = AuthState.authenticated(appUser);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // Logout method
  Future<void> logout() async {
    await _authRepository.signOut();
    state = AuthState.unauthenticated();
  }
}


enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final String? loadingMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.loadingMessage,
  });

  // Convenience constructors
  factory AuthState.loading({String? message}) => AuthState(status: AuthStatus.loading, loadingMessage: message);
  factory AuthState.authenticated(AppUser user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}
