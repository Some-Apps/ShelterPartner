import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/views/auth/login_or_signup.dart';
import 'package:shelter_partner/views/pages/main_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Assuming MainPage is where the authenticated user goes

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state from the authViewModelProvider
    final authState = ref.watch(authViewModelProvider);

    // Dismiss the loading dialog when authState is no longer loading
    if (authState.status != AuthStatus.loading) {
      Future.microtask(() {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Dismiss the loading dialog
        }
      });
    }

    return Scaffold(
      body: authState.status == AuthStatus.loading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : authState.status == AuthStatus.authenticated
              ? MainPage(appUser: authState.user!) // Authenticated, show MainPage
              : authState.status == AuthStatus.unauthenticated
                  ? const LoginOrSignup() // Unauthenticated, show login/signup screen
                  : authState.status == AuthStatus.error
                      ? Center(
                          child: Text(
                            'Error: ${authState.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator()), // Fallback in case of unexpected state
    );
  }
}
