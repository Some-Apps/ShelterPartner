import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:email_validator/email_validator.dart';

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

  bool _hasSentInvite = false;

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

  void _confirmDeleteVolunteer(BuildContext context, String volunteerId,
      String shelterId, String volunteerName) {
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterDetailsViewModelProvider);
    final volunteerInviteState = ref.watch(volunteersViewModelProvider);

    return SafeArea(
      child: GestureDetector(
        onTap: () => _unfocusTextFields(context),
        child: shelterAsyncValue.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
          data: (shelter) => Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  Card.outlined(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text("Volunteer Settings"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/volunteers/volunteer-settings');
                          },
                        ),
                        Divider(
                          color: Colors.black.withOpacity(0.1),
                          height: 0,
                          thickness: 1,
                        ),
                        ListTile(
                          leading: const Icon(Icons.sync),
                          title: const Text("Sync With Better Impact"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/volunteers/better-impact');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Invite a Volunteer",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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
                                final email = _emailController.text.trim();
                                ref
                                    .read(volunteersViewModelProvider.notifier)
                                    .sendVolunteerInvite(firstName, lastName,
                                        email, shelter!.id);
                                _hasSentInvite = true;
                              }
                            },
                            child: const Text('Send Invite'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Volunteers",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (shelter!.volunteers.isNotEmpty)
                            ...shelter.volunteers.map(
                              (volunteer) => Column(
                                children: [
                                  ListTile(
                                    title: Text(volunteer.firstName),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.red.withOpacity(0.5)),
                                      onPressed: () {
                                        _confirmDeleteVolunteer(
                                          context,
                                          volunteer.id,
                                          shelter.id,
                                          volunteer.firstName,
                                        );
                                      },
                                    ),
                                    onTap: () {
                                      context.push(
                                        '/volunteers/details',
                                        extra: volunteer,
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.black.withOpacity(0.1),
                                    height: 0,
                                    thickness: 1,
                                  ),
                                ],
                              ),
                            )
                          else
                            const Text('No volunteers available at the moment'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
