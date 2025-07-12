// auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/views/auth/login_or_signup.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);

    // Handle error state with toast and reset state
    if (authState.status == AuthStatus.error) {
      Future.microtask(() {
        Fluttertoast.showToast(
          msg: authState.errorMessage ?? 'An unknown error occurred',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        authViewModel.resetState();
      });

      return const LoginOrSignup();
    }

    // Show loading indicator when logging in or logging out
    if (authState.status == AuthStatus.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(authState.loadingMessage ?? "Loading..."),
            ],
          ),
        ),
      );
    }

    // Redirect to home page after authentication
    if (authState.status == AuthStatus.authenticated) {
      final appUser = ref.read(authViewModelProvider).user;

      if (appUser != null) {
        Future.microtask(() {
          ref.read(appUserProvider.notifier).state =
              appUser; // Store appUser globally
          if (context.mounted) {
            context.go('/enrichment'); // No need to pass appUser here
          }
        });
      } else {
        Future.microtask(() {
          Fluttertoast.showToast(
            msg: "Failed to fetch user information.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        });
      }

      // Return SizedBox.shrink() while processing the navigation
      return const SizedBox.shrink();
    }

    // Default to Login or Signup page
    return const LoginOrSignup();
  }
} /*  */

enum AuthPageType { login, signup, forgotPassword }

class AuthPageNotifier extends StateNotifier<AuthPageType> {
  AuthPageNotifier() : super(AuthPageType.login);

  // Update the current page
  void setPage(AuthPageType pageType) {
    state = pageType;
  }
}

// Provide the AuthPageNotifier using Riverpod
final authPageProvider = StateNotifierProvider<AuthPageNotifier, AuthPageType>(
  (ref) => AuthPageNotifier(),
);
