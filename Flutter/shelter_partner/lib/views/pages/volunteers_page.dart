import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/views/pages/volunteer_detail_page.dart';
import 'package:shelter_partner/views/pages/volunteer_settings_page.dart';

class VolunteersPage extends ConsumerStatefulWidget {
  const VolunteersPage({super.key});

  @override
  _VolunteersPageState createState() => _VolunteersPageState();
}

class _VolunteersPageState extends ConsumerState<VolunteersPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterDetailsViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text("Volunteers (only admin accounts)"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text("Volunteers (only admin accounts)"),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        appBar: AppBar(
          title: const Text("Volunteers (only admin accounts)"),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Volunteer Settings Section
                  Card(
                    child: ListTile(
                      title: const Text("Volunteer Settings"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Use GoRouter to navigate to VolunteerSettingsPage
                        context.push(
                            '/volunteers/volunteer-settings'); // Ensure you have this route defined in GoRouter
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Invite a Volunteer Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Invite a Volunteer",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'Volunteer name',
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: 'Volunteer email',
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Handle send invite action
                            },
                            child: const Text('Send Invite'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Volunteers List Section
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Volunteers",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          // Reuse NavigationButton widget
                          NavigationButton(
                              title: "Example Volunteer",
                              route: '/volunteers/details/1'),
                          NavigationButton(
                              title: "Example Volunteer",
                              route: '/volunteers/detail/2'),
                          NavigationButton(
                              title: "Example Volunteer",
                              route: '/volunteers/details/3'),
                        ],
                      ),
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

