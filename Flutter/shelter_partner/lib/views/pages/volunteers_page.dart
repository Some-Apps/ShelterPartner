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

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _hasSentInvite = false; // Track if invite has been sent by the user

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _unfocusTextFields(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  void _confirmDeleteVolunteer(BuildContext context, String volunteerId, String shelterId, String volunteerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete $volunteerName?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await ref
                      .read(volunteersViewModelProvider.notifier)
                      .deleteVolunteer(volunteerId, shelterId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$volunteerName deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete volunteer: $e')),
                  );
                }
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(volunteersViewModelProvider, (previous, next) {
      if (next.isLoading) {
        // Do nothing; the loading indicator will be shown
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
          ),
        );
        // Handle error case
      } else if (!next.isLoading && next.hasValue && _hasSentInvite) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent successfully')),
        );
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _hasSentInvite = false; // Reset the flag after showing the message
      }
    });

    final shelterAsyncValue = ref.watch(shelterDetailsViewModelProvider);
    final volunteerInviteState = ref.watch(volunteersViewModelProvider);

    return GestureDetector(
      onTap: () => _unfocusTextFields(context),
      child: shelterAsyncValue.when(
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
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    labelText: 'Volunteer first name',
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the volunteer\'s first name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    labelText: 'Volunteer last name',
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the volunteer\'s last name';
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
                                      final firstName =
                                          _firstNameController.text.trim();
                                      final lastName =
                                          _lastNameController.text.trim();
                                      final email =
                                          _emailController.text.trim();
                                      ref
                                          .read(volunteersViewModelProvider
                                              .notifier)
                                          .sendVolunteerInvite(firstName, lastName, email, shelter!.id);
                                      _hasSentInvite = true; // Set the flag when invite is sent
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
                                  ...shelter.volunteers.map(
                                    (volunteer) => Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: NavigationButton(
                                            title: volunteer.firstName,
                                            route: '/volunteers/details/${volunteer.firstName}',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            _confirmDeleteVolunteer(
                                              context,
                                              volunteer.id,
                                              shelter.id,
                                              volunteer.firstName,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ).toList()
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
      ),
    );
  }
}
