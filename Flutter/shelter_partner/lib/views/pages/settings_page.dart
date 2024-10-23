import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterDetailsViewModelProvider);
    final appUser = ref.watch(appUserProvider);

    return shelterAsyncValue.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Display loading indicator while fetching data
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (appUser?.type == 'admin') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Shelter Details:"),
                            Text("Shelter: ${shelter?.name}"),
                            Text("ID: ${shelter?.id}"),
                            Text("Address: ${shelter?.address}"),
                            Text("Software: ${shelter?.managementSoftware}"),
                            Text(
                                "Created: ${shelter?.createdAt.toDate().day}/${shelter?.createdAt.toDate().month}/${shelter?.createdAt.toDate().year}"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: ListTile(
                        title: const Text("Shelter Settings"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/settings/shelter-settings');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: ListTile(
                        title: const Text("Device Settings"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/settings/device-settings');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Card(
                    child: ListTile(
                      title: Text("Toggle Account Type: ${appUser?.type}"),
                      trailing: const Icon(Icons.swap_horiz),
                      onTap: () async {
                        final currentType = appUser?.type;
                        final newType =
                            currentType == 'admin' ? 'volunteer' : 'admin';
                        try {
                          // Assuming you have a Firestore instance and user ID
                          final firestore = FirebaseFirestore.instance;
                          final userId = appUser?.id;

                          if (userId != null) {
                            await firestore
                                .collection('users')
                                .doc(userId)
                                .update({'type': newType});
                            // Update the appUser provider with the new type
                            ref.read(appUserProvider.notifier).update(
                                (state) => state?.copyWith(type: newType));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Account type changed to $newType')),
                            );
                          } else {
                            throw Exception('User ID is null');
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error changing account type: $e')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      title: const Text("Logout"),
                      trailing: const Icon(Icons.logout),
                      onTap: () {
                        ref
                            .read(authViewModelProvider.notifier)
                            .logout(context, ref);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      title: const Text("Delete Account"),
                      subtitle: const Text(
                          "This won't be in the final app but I'd recommend deleting your account and recreating it every once in a while because the organization of the app is going to change a lot so stuff may break for old accounts."),
                      trailing: const Icon(Icons.delete, color: Colors.red),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirm Deletion"),
                            content: const Text(
                                "Are you sure you want to delete your account? This action cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Delete",
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final emailController = TextEditingController();
                          final passwordController = TextEditingController();

                          final credentialsConfirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Enter Credentials"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: emailController,
                                    decoration: const InputDecoration(
                                      labelText: "Email",
                                    ),
                                  ),
                                  TextField(
                                    controller: passwordController,
                                    decoration: const InputDecoration(
                                      labelText: "Password",
                                    ),
                                    obscureText: true,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Confirm"),
                                ),
                              ],
                            ),
                          );

                          if (credentialsConfirmed == true) {
                            final email = emailController.text;
                            final password = passwordController.text;
                            try {
                              await ref
                                  .read(authViewModelProvider.notifier)
                                  .deleteAccount(context, email, password);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error reauthenticating user: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
