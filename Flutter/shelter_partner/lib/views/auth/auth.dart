import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelter_partner/repositories/app_user_repository.dart';
import 'package:shelter_partner/view_models/app_user_view_model.dart';
import 'package:shelter_partner/views/auth/login_or_signup.dart';
import 'package:shelter_partner/views/pages/main_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print('Auth state change detected');
          if (snapshot.hasData) {
            final firebase_auth.User firebaseUser = snapshot.data!;

            // Wait for user verification and creation
            return FutureBuilder<bool>(
              future: _handleUserCreation(firebaseUser),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (userSnapshot.hasError || !userSnapshot.data!) {
                  // If there was an error or the user does not exist, sign out
                  return const LoginOrSignup();
                } else {
                  // User exists and is authenticated, and the document has been created
                  return ChangeNotifierProvider(
                    create: (context) => AppUserViewModel(userRepository: AppUserRepository())
                      ..fetchUser(firebaseUser.uid),
                    child: Consumer<AppUserViewModel>(
                      builder: (context, appUserViewModel, child) {
                        if (appUserViewModel.currentUser == null) {
                          print('User data not yet loaded from Firestore');
                          return const Center(child: CircularProgressIndicator());
                        }
                        print('User loaded from Firestore: ${appUserViewModel.currentUser?.shelterId}');
                        return MainPage(appUser: appUserViewModel.currentUser);
                      },
                    ),
                  );
                }
              },
            );
          } else {
            print('No user logged in, showing login screen');
            return const LoginOrSignup();
          }
        },
      ),
    );
  }

  Future<bool> _handleUserCreation(firebase_auth.User firebaseUser) async {
    // Here we are waiting for the user document to be created before proceeding
    try {
      // Assume the `AppUserRepository` creates the Firestore user document
      final appUserRepository = AppUserRepository();
      final userExists = await appUserRepository.getUserById(firebaseUser.uid);
      
      print('User document creation successful or already exists');
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
}
