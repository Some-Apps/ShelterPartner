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
          child: CircularProgressIndicator(),
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
                  const SizedBox(height: 25),
                  // Text("Settings",
                  //     style: Theme.of(context).textTheme.titleLarge),
                  Card.outlined(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: const Text("Shelter Settings"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/settings/shelter-settings');
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.devices),
                          title: const Text("Device Settings"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/settings/device-settings');
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: Text("Toggle Account Type: ${appUser?.type}"),
                          onTap: () async {
                            final currentType = appUser?.type;
                            final newType =
                                currentType == 'admin' ? 'volunteer' : 'admin';
                            try {
                              final firestore = FirebaseFirestore.instance;
                              final userId = appUser?.id;

                              if (userId != null) {
                                await firestore
                                    .collection('users')
                                    .doc(userId)
                                    .update({'type': newType});
                                ref.read(appUserProvider.notifier).state =
                                    appUser?.copyWith(type: newType);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Account type changed to $newType')),
                                );
                              } else {
                                throw Exception('User ID is null');
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error changing account type: $e')),
                              );
                            }
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text("Logout"),
                          onTap: () {
                            ref
                                .read(authViewModelProvider.notifier)
                                .logout(context);
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text("Delete Account"),
                          subtitle: const Text(
                              "This won't be in the final app but I'd recommend deleting your account and recreating it every once in a while because the organization of the app is going to change a lot so stuff may break for old accounts."),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm Deletion"),
                                content: const Text(
                                    "Are you sure you want to delete your account? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final emailController = TextEditingController();
                              final passwordController =
                                  TextEditingController();

                              final credentialsConfirmed =
                                  await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Enter Credentials"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: emailController,
                                        decoration: const InputDecoration(
                                            labelText: "Email"),
                                      ),
                                      TextField(
                                        controller: passwordController,
                                        decoration: const InputDecoration(
                                            labelText: "Password"),
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
                                        content: Text(
                                            'Error reauthenticating user: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Text("About", style: Theme.of(context).textTheme.titleLarge),
                  Card.outlined(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const ListTile(
                          leading: Icon(Icons.favorite_border),
                          title: Text("Support Us And Remove Ads"),
                          trailing: Icon(Icons.chevron_right),
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        const ListTile(
                          leading: Icon(Icons.help_outline),
                          title: Text("Wiki"),
                          trailing: Icon(Icons.chevron_right),
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text("Acknowledgements"),
                          trailing: Icon(Icons.chevron_right),
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        const ListTile(
                          leading: Icon(Icons.numbers, color: Colors.grey),
                          title: Text("Version 2.0.0",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        const ListTile(
                          leading: Icon(Icons.pets, color: Colors.grey),
                          title: Text("Dedicated to Aslan",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ],
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
