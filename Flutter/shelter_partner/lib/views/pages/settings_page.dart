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

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text("Settings (only admin accounts)"),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(), // Display loading indicator while fetching data
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text("Settings (only admin accounts)"),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        appBar: AppBar(
          title: const Text("Settings (only admin accounts)"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
