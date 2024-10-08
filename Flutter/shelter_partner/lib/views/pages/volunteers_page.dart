import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:email_validator/email_validator.dart'; // Add this package to pubspec.yaml

class VolunteersPage extends ConsumerStatefulWidget {
  const VolunteersPage({super.key});

  @override
  _VolunteersPageState createState() => _VolunteersPageState();
}

class _VolunteersPageState extends ConsumerState<VolunteersPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(volunteersViewModelProvider, (previous, next) {
      if (next.isLoading) {
        // Do nothing; the loading indicator will be shown
      } else if (next.hasError) {
        final error = next.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending invite: $error')),
        );
        print('Error sending invite: $error');
      } else if (!next.isLoading && next.hasValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent successfully')),
        );
        _nameController.clear();
        _emailController.clear();
      }
    });

    final shelterAsyncValue = ref.watch(shelterDetailsViewModelProvider);
    final volunteerInviteState = ref.watch(volunteersViewModelProvider);

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
        body: Stack(
          children: [
            SingleChildScrollView(
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
                            context.push('/volunteers/volunteer-settings');
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
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                  labelText: 'Volunteer name',
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the volunteer name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                  labelText: 'Volunteer email',
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the volunteer email';
                                  } else if (!EmailValidator.validate(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final name = _nameController.text.trim();
                                    final email = _emailController.text.trim();
                                    ref.read(volunteersViewModelProvider.notifier).sendVolunteerInvite(name, email, shelter!.id);
                                  }
                                },
                                child: const Text('Send Invite'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Volunteers List Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Volunteers",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (shelter!.volunteers.isNotEmpty)
                                ...shelter.volunteers
                                    .map((volunteer) => NavigationButton(
                                          title: volunteer.name,
                                          route: '/volunteers/details/${volunteer.name}',
                                        ))
                                    .toList()
                              else
                                const Text('No volunteers available at the moment'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Show progress indicator when loading
            if (volunteerInviteState.isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  // Removed duplicate build method
}
