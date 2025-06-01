import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

// Providers
final usersWithEmailProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);
final usersToAddProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);
final usersToRemoveProvider = StateProvider<List<Volunteer>>((ref) => []);

class BetterImpactPage extends ConsumerStatefulWidget {
  const BetterImpactPage({super.key});

  @override
  _BetterImpactPageState createState() => _BetterImpactPageState();
}

class _BetterImpactPageState extends ConsumerState<BetterImpactPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false; // Local loading state

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Move the sync function outside of the build method
  Future<void> sync() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String username = usernameController.text.trim();
      final String password = passwordController.text.trim();

      // Validate inputs
      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter username and password.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Endpoint of your Cloud Function - replace with your actual URL
      const String functionUrl =
          'https://sync-better-impact-222422545919.us-central1.run.app';

      // Replace 'your-project-id' with your actual Firebase project ID
      // Example: 'https://us-central1-my-firebase-project-id.cloudfunctions.net/syncBetterImpact';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle unauthenticated user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      // final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Parse the response from the Cloud Function
        final data = json.decode(response.body);
        final List<dynamic> users = data['users'];

        // Proceed with your existing logic
        final usersWithEmail = users
            .where(
              (user) =>
                  user['email_address'] != null &&
                  user['email_address'].isNotEmpty,
            )
            .map(
              (user) => {
                'first_name': user['first_name'],
                'last_name': user['last_name'],
                'email_address': user['email_address'],
              },
            )
            .toList();

        ref.read(usersWithEmailProvider.notifier).state = usersWithEmail;

        // Get shelterID from authViewModelProvider
        final authState = ref.read(authViewModelProvider);
        if (authState.status != AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
        final shelterID = authState.user?.shelterId;
        if (shelterID == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shelter ID not found.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Get existing volunteers from volunteersViewModelProvider
        final volunteersState = ref.read(volunteersViewModelProvider);
        if (volunteersState is AsyncLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Volunteer data is loading. Please try again.'),
            ),
          );
          setState(() {
            isLoading = false;
          });
          return;
        } else if (volunteersState is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error loading volunteer data: ${volunteersState.error}',
              ),
            ),
          );
          setState(() {
            isLoading = false;
          });
          return;
        } else if (volunteersState is AsyncData<Shelter?>) {
          final shelter = volunteersState.value;
          if (shelter == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No shelter data available.')),
            );
            setState(() {
              isLoading = false;
            });
            return;
          }

          final existingVolunteers = shelter.volunteers;

          // Get emails from API response and existing volunteers
          final Set<String> apiEmails = usersWithEmail
              .map((user) => user['email_address'] as String)
              .toSet();

          final Set<String> volunteerEmails = existingVolunteers
              .map((volunteer) => volunteer.email)
              .toSet();

          // Determine emails to add and remove
          final Set<String> emailsToAdd = apiEmails.difference(volunteerEmails);
          final Set<String> emailsToRemove = volunteerEmails.difference(
            apiEmails,
          );

          // Get users to add
          final List<Map<String, dynamic>> usersToAdd = usersWithEmail
              .where((user) => emailsToAdd.contains(user['email_address']))
              .toList();

          final List<Volunteer> usersToRemove = existingVolunteers
              .where((volunteer) => emailsToRemove.contains(volunteer.email))
              .toList();

          // Update state providers
          ref.read(usersToAddProvider.notifier).state = usersToAdd;
          ref.read(usersToRemoveProvider.notifier).state = usersToRemove;

          // Show the dialog and wait for the result
          final shouldSync = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return SyncDialog(shelterID: shelterID);
            },
          );

          if (shouldSync == true) {
            // Proceed with adding and removing volunteers
            try {
              // Convert usersToAdd to List<Volunteer>
              final volunteersToAdd = usersToAdd.map((user) {
                return Volunteer(
                  id: const Uuid()
                      .v4(), // Assign an appropriate ID if necessary
                  firstName: user['first_name'],
                  lastName: user['last_name'],
                  email: user['email_address'],
                  shelterID: shelterID,
                  lastActivity: Timestamp.now(),
                  averageLogDuration: 0,
                  totalTimeLoggedWithAnimals: 0,
                );
              }).toList();

              // Add new volunteers
              for (var volunteer in volunteersToAdd) {
                await ref
                    .read(volunteersViewModelProvider.notifier)
                    .sendVolunteerInvite(
                      volunteer.firstName,
                      volunteer.lastName,
                      volunteer.email,
                      shelterID,
                    );
              }

              // Remove volunteers
              for (var volunteer in usersToRemove) {
                try {
                  await ref
                      .read(volunteersViewModelProvider.notifier)
                      .deleteVolunteer(volunteer.id, shelterID);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete volunteer: $e')),
                  );
                }
              }

              // Show success toast
              Fluttertoast.showToast(
                msg:
                    "${usersToAdd.length} volunteers added, ${usersToRemove.length} volunteers removed",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.TOP,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 16.0,
              );

              // Navigate back to /volunteers
              context.go('/volunteers');
            } catch (e) {
              // Handle any errors
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error during sync: $e')));
            }
          }
        } else {
          // Should not reach here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected error occurred.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
      } else {
        // Handle error response from Cloud Function
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync users: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle exceptions
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during sync: $e')));
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Better Impact Sync')),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: isLoading, // Prevent interaction when loading
            child: Opacity(
              opacity: isLoading ? 0.5 : 1.0, // Fade background when loading
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            "Important: Please Read",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "This will add new users who are volunteers in Better Impact and whose status is \"Accepted\" and remove users who are no longer in Better Impact or whose status is no longer \"Accepted\".",
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Because of privacy laws, volunteers will not stay up to date automatically. You will have to come back here whenever you want to resync the volunteers. The username and password are NOT your normal login. They are generated by following the link below. Make sure to only select the \"Volunteer\" checkbox when creating the key. The username and password will not be saved anywhere and will only be used to sync your volunteers.",
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () async {
                              const url =
                                  'https://support.betterimpact.com/volunteerimpacthelp/en/help-articles/it/';
                              if (await canLaunch(url)) {
                                await launch(url);
                              } else {
                                throw 'Could not launch $url';
                              }
                            },
                            child: const Text(
                              'How To Generate Username and Password (API Key)',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                          ),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : sync,
                            child: const Text('Sync'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class SyncDialog extends ConsumerWidget {
  final String shelterID;
  const SyncDialog({super.key, required this.shelterID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersToAdd = ref.watch(usersToAddProvider);
    final usersToRemove = ref.watch(usersToRemoveProvider);

    return AlertDialog(
      title: const Text('Users to Sync'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (usersToAdd.isNotEmpty) ...[
                const Text(
                  'Add:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: usersToAdd.length,
                  itemBuilder: (context, index) {
                    final user = usersToAdd[index];
                    return ListTile(
                      title: Text(
                        '${user['first_name']} ${user['last_name']}: ${user['email_address']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref.read(usersToAddProvider.notifier).state =
                              usersToAdd.where((u) => u != user).toList();
                        },
                      ),
                    );
                  },
                ),
              ],
              if (usersToRemove.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Remove:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: usersToRemove.length,
                  itemBuilder: (context, index) {
                    final volunteer = usersToRemove[index];
                    return ListTile(
                      title: Text(
                        '${volunteer.firstName} ${volunteer.lastName}: ${volunteer.email}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref
                              .read(usersToRemoveProvider.notifier)
                              .state = usersToRemove
                              .where((v) => v != volunteer)
                              .toList();
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true); // Dismiss and proceed with sync
          },
          child: const Text('Sync'),
        ),
      ],
    );
  }
}
