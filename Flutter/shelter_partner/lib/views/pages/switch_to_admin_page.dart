import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';

class SwitchToAdminPage extends ConsumerWidget {
  const SwitchToAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController passwordController = TextEditingController();

    Future<void> switchToAdmin(
      BuildContext context,
      WidgetRef ref,
      String password,
    ) async {
      try {
        // Reauthenticate the user with the provided password
        final user = FirebaseAuth.instance.currentUser;
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // If reauthentication is successful, optimistically update the AppUser state to reflect the admin mode
        final appUser = ref.read(appUserProvider.notifier).state;
        final updatedAppUser = appUser!.copyWith(
          accountSettings: appUser.accountSettings?.copyWith(mode: 'Admin'),
        );

        // Update the provider with the new state
        ref.read(appUserProvider.notifier).state = updatedAppUser;

        // Also update the backend to persist the change
        await ref
            .read(accountSettingsViewModelProvider.notifier)
            .modifyAccountSettingString(appUser.id, "mode", "Admin");

        // Navigate to the first tab of the Admin layout
        if (context.mounted) {
          context.go('/enrichment');
        }

        // Provide feedback or navigation if needed
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Switched to Admin mode')));
      } catch (e) {
        // Handle error (e.g., show a snackbar with an error message)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Incorrect password')));
      }
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Switch to Admin Page'),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => switchToAdmin(context, ref, value),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  switchToAdmin(context, ref, passwordController.text),
              child: const Text('Switch to admin'),
            ),
          ],
        ),
      ),
    );
  }
}
