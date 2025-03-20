import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';

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

  bool isLoading = false; // Local loading state

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sortVolunteers("Ascending");
  }

  void _unfocusTextFields(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  void _confirmDeleteVolunteer(
      BuildContext context, String volunteerId, String volunteerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final shelterID = ref.read(authViewModelProvider).user?.shelterId ?? '';

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
    Navigator.of(context).pop(); // Dismiss the dialog first
    setState(() {
      isLoading = true;
    });
    try {
      await ref
          .read(volunteersViewModelProvider.notifier)
          .deleteVolunteer(volunteerId, shelterID);
      // Refresh the volunteers list from the provider.
      ref.refresh(volunteersViewModelProvider);
      // Clear local filtered list so the new data is used.
      setState(() {
        filteredVolunteers = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$volunteerName deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete volunteer: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  },
),
          ],
        );
      },
    );
  }

  List<Volunteer> filteredVolunteers = [];
  String _sortOrder = "Ascending";

  void _filterVolunteers(Shelter shelter, String query) {
    setState(() {
      filteredVolunteers = shelter.volunteers.where((volunteer) {
        final fullName =
            '${volunteer.firstName} ${volunteer.lastName}'.toLowerCase();
        return fullName.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _sortVolunteers(String order) {
    setState(() {
      _sortOrder = order;
      filteredVolunteers.sort((a, b) {
        int comparison = a.firstName.compareTo(b.firstName);
        return order == "Ascending" ? comparison : -comparison;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(volunteersViewModelProvider);
    final shelterID = ref.read(authViewModelProvider).user?.shelterId ?? '';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Stack(
            children: [
              Form(
                key: _formKey,
                child: GestureDetector(
                  onTap: () => _unfocusTextFields(context),
                  child: shelterAsyncValue.when(
                      loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                      error: (error, stack) => Center(
                            child: Text('Error: $error'),
                          ),
                      data: (shelter) {
                        if (shelter == null) {
                          const Center(
                              child: Text("No shelter data available"));
                        }
                        if (filteredVolunteers.isEmpty) {
                          filteredVolunteers = List.from(shelter!.volunteers);
                        }
                        return AbsorbPointer(
                          absorbing: isLoading,
                          child: Opacity(
                            opacity: isLoading ? 0.5 : 1.0,
                            child: Scaffold(
                              body: SingleChildScrollView(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 25),
                                    Card.outlined(
                                      child: ListView(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.settings),
                                            title: const Text(
                                                "Volunteer Settings"),
                                            trailing:
                                                const Icon(Icons.chevron_right),
                                            onTap: () {
                                              context.push(
                                                  '/volunteers/volunteer-settings');
                                            },
                                          ),
                                          // Divider(
                                          //   color:
                                          //       Colors.black.withOpacity(0.1),
                                          //   height: 0,
                                          //   thickness: 1,
                                          // ),
                                          // ListTile(
                                          //   leading: const Icon(Icons.sync),
                                          //   title: const Text(
                                          //       "Sync With Better Impact"),
                                          //   trailing:
                                          //       const Icon(Icons.chevron_right),
                                          //   onTap: () {
                                          //     context.push(
                                          //         '/volunteers/better-impact');
                                          //   },
                                          // ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    Card.outlined(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Invite a Volunteer",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 10),
                                            TextFormField(
                                              controller: _firstNameController,
                                              decoration: const InputDecoration(
                                                border: UnderlineInputBorder(),
                                                labelText:
                                                    'Volunteer first name',
                                                contentPadding:
                                                    EdgeInsets.all(16),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
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
                                                labelText:
                                                    'Volunteer last name',
                                                contentPadding:
                                                    EdgeInsets.all(16),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
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
                                                contentPadding:
                                                    EdgeInsets.all(16),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter the volunteer email';
                                                } else if (!EmailValidator
                                                    .validate(value)) {
                                                  return 'Please enter a valid email address';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),
                                            ElevatedButton(
                                              onPressed: isLoading
                                                  ? null
                                                  : () async {
                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        setState(() {
                                                          isLoading = true;
                                                        });
                                                        final firstName =
                                                            _firstNameController
                                                                .text
                                                                .trim();
                                                        final lastName =
                                                            _lastNameController
                                                                .text
                                                                .trim();
                                                        final email =
                                                            _emailController
                                                                .text
                                                                .trim();

                                                        try {
                                                          await ref
                                                              .read(
                                                                  volunteersViewModelProvider
                                                                      .notifier)
                                                              .sendVolunteerInvite(
                                                                  firstName,
                                                                  lastName,
                                                                  email,
                                                                  shelterID);

                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Invite sent successfully')),
                                                          );

                                                          setState(() {
                                                            filteredVolunteers =
                                                                shelter!
                                                                    .volunteers
                                                                    .toList();
                                                          });


                                                          setState(() {
                                                            filteredVolunteers =
                                                                shelter!
                                                                    .volunteers
                                                                    .toList();
                                                          });

                                                          // Clear the text fields
                                                          _firstNameController
                                                              .clear();
                                                          _lastNameController
                                                              .clear();
                                                          _emailController
                                                              .clear();
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                                content: Text(
                                                                    'Failed to send invite: $e')),
                                                          );
                                                        } finally {
                                                          setState(() {
                                                            isLoading = false;
                                                          });
                                                        }
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Volunteers",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                //Search Bar
                                                Expanded(
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'Search Volunteers',
                                                      prefixIcon: const Icon(
                                                          Icons.search,
                                                          color: Colors.grey),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              vertical: 12.0),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                        borderSide: BorderSide(
                                                          color: Colors.grey
                                                              .withOpacity(0.5),
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                        borderSide:
                                                            const BorderSide(
                                                                color: Colors
                                                                    .blue),
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.grey
                                                          .withOpacity(0.05),
                                                    ),
                                                    onChanged: (value) {
                                                      _filterVolunteers(
                                                          shelter!, value);
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                //Sorting dropdown
                                                DropdownButtonHideUnderline(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12.0),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.grey
                                                            .withOpacity(0.5),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    child:
                                                        DropdownButton<String>(
                                                      value: _sortOrder,
                                                      items: const [
                                                        DropdownMenuItem(
                                                          value: "Ascending",
                                                          child: Text("A-Z"),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: "Descending",
                                                          child: Text("Z-A"),
                                                        ),
                                                      ],
                                                      onChanged: (value) {
                                                        if (value != null) {
                                                          _sortVolunteers(
                                                              value);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            if (shelter!.volunteers.isNotEmpty)
                                              Column(
                                                children: filteredVolunteers
                                                    .map((volunteer) {
                                                  return Column(
                                                    children: [
                                                      ListTile(
                                                        leading: DateTime.now()
                                                                    .difference(volunteer
                                                                        .lastActivity
                                                                        .toDate())
                                                                    .inHours <
                                                                1
                                                            ? const Icon(
                                                                Icons.circle,
                                                                color: Colors
                                                                    .green)
                                                            : const Icon(
                                                                Icons.circle,
                                                                color: Colors
                                                                    .grey),
                                                        title: Text(
                                                            '${volunteer.firstName} ${volunteer.lastName}'),
                                                        trailing: IconButton(
                                                          icon: Icon(
                                                              Icons.delete,
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                      0.5)),
                                                          onPressed: () {
                                                            _confirmDeleteVolunteer(
                                                              context,
                                                              volunteer.id,
                                                              volunteer
                                                                  .firstName,
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
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        height: 0,
                                                        thickness: 1,
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              )
                                            else
                                              const Text(
                                                  'No volunteers available at the moment'),
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
                        );
                      }),
                ),
              ),
              if (isLoading)
                Center(
                  child: Container(
                    color: Colors.black.withOpacity(0.5), // Faded background
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
