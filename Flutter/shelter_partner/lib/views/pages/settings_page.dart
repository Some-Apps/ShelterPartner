import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;

class SettingsPage extends ConsumerStatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String csvData = "Loading CSV...";

  @override
  void initState() {
    super.initState();
    _loadCSV();
  }

  Future<void> _loadCSV() async {
    try {
      final csvString = await rootBundle.loadString('assets/cats.csv');
      setState(() {
        csvData = csvString;
      });
    } catch (e) {
      setState(() {
        csvData = "Failed to load CSV.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              // Call the logout method when the button is pressed
              ref.read(authViewModelProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Text("Logged in as: ${viewModel.user?.email ?? 'Unknown'}"),
            const Text("Settings Page"),
            const SizedBox(height: 20),
            Text(csvData),
          ],
        ),
      ),
    );
  }
}

