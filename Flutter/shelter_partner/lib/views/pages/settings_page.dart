import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final shelter = ref.watch(shelterDetailsViewModelProvider);

    // Check if shelter is null, and display a loading or empty state if needed
    if (shelter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: const Center(
          child: CircularProgressIndicator(), // Display loading indicator while fetching data
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Log out"),
                    IconButton(
                      onPressed: () {
                        ref.read(authViewModelProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Account Details"),
                _buildInsetForm([
                  Text("Shelter ID: ${shelter.id}"),
                  Text("Shelter Address: ${shelter.address}"),
                  Text("Shelter Creation: ${shelter.createdAt.toString()}"),
                  Text("Management Software: ${shelter.managementSoftware}"),
                ]),
                const SizedBox(height: 20),
                _buildSectionTitle("Shelter Settings"),
                _buildInsetForm([
                  Text("Example: ${shelter.shelterSettings.setting1}"),

                ]),
                const SizedBox(height: 20),
                _buildSectionTitle("Volunteer Settings"),
                _buildInsetForm([
                  Text("Example: ${shelter.volunteerSettings.setting1}")
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInsetForm(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
