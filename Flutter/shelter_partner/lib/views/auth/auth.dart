import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelter_partner/repositories/app_user_repository.dart';
import 'package:shelter_partner/view_models/app_user_view_model.dart';
import 'package:shelter_partner/views/auth/login_or_signup.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<firebase_auth.User?>(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print('Auth state change detected');
          if (snapshot.hasData) {
            final firebase_auth.User firebaseUser = snapshot.data!;

            // Listen to the user document in Firestore
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(firebaseUser.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  // User document does not exist yet
                  print('Waiting for user document to be created');
                  return const Center(child: CircularProgressIndicator());
                } else {
                  // User document exists, proceed to main page
                  print('User document found, proceeding to main page');

                  // Initialize AppUserViewModel with the current user data
                  return ChangeNotifierProvider(
                    create: (context) => AppUserViewModel(
                      userRepository: AppUserRepository(),
                    )..setCurrentUserFromDocument(userSnapshot.data!),
                    child: Consumer<AppUserViewModel>(
                      builder: (context, appUserViewModel, child) {
                        if (appUserViewModel.currentUser == null) {
                          print('User data not yet loaded from Firestore');
                          return const Center(child: CircularProgressIndicator());
                        }
                        print(
                            'User loaded from Firestore: ${appUserViewModel.currentUser?.shelterId}');
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
}
