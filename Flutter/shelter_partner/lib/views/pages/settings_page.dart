import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/github_release.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/views/components/release_notes.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String _version = "Loading...";
  List<GitHubRelease> _releases = [];
  bool _showPreviousVersions = false;
  Set<int> _expandedReleases = {0}; // Only the latest is expanded by default

  @override
  void initState() {
    super.initState();
    _fetchVersion();
    fetchFilteredReleases().then((releases) {
      setState(() {
        _releases = releases;
      });
    });
  }

  Future<void> _fetchVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = "Version ${packageInfo.version}+${packageInfo.buildNumber}";
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterDetailsViewModelProvider);
    final appUser = ref.watch(appUserProvider);

    return shelterAsyncValue.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (shelter) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            // padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            "General",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Card.outlined(
                          child: ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              if (appUser?.type == 'admin') ...[
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
                                  leading: const Icon(Icons.bar_chart),
                                  title: const Text("Shelter Stats"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push('/settings/stats');
                                  },
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                                ListTile(
                                  leading: const Icon(Icons.devices),
                                  title: const Text("Account Settings"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push('/settings/account-settings');
                                  },
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                              ],
                              // ListTile(
                              //   leading: const Icon(Icons.swap_horiz),
                              //   title: Text(
                              //       "Toggle Account Type: ${appUser?.type}"),
                              //   subtitle: const Text(
                              //       "Just for testing. Not in final app."),
                              //   onTap: () async {
                              //     final currentType = appUser?.type;
                              //     final newType = currentType == 'admin'
                              //         ? 'volunteer'
                              //         : 'admin';
                              //     try {
                              //       final firestore =
                              //           FirebaseFirestore.instance;
                              //       final userId = appUser?.id;

                              //       if (userId != null) {
                              //         await firestore
                              //             .collection('users')
                              //             .doc(userId)
                              //             .update({'type': newType});
                              //         ref.read(appUserProvider.notifier).state =
                              //             appUser?.copyWith(type: newType);

                              //         ScaffoldMessenger.of(context)
                              //             .showSnackBar(
                              //           SnackBar(
                              //               content: Text(
                              //                   'Account type changed to $newType')),
                              //         );
                              //       } else {
                              //         throw Exception('User ID is null');
                              //       }
                              //     } catch (e) {
                              //       ScaffoldMessenger.of(context).showSnackBar(
                              //         SnackBar(
                              //             content: Text(
                              //                 'Error changing account type: $e')),
                              //       );
                              //     }
                              //   },
                              // ),
                              Divider(
                                color: Colors.black.withOpacity(0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                leading: const Icon(Icons.lock_outline),
                                title: const Text("Change Password"),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  context.push('/settings/change-password');
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
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Account"),
                                      content: const Text(
                                        "To delete your account and all data associated with it, please email jared@shelterpartner.org",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // ListTile(
                              //   leading: const Icon(Icons.delete_outline),
                              //   title: const Text("Delete Account"),
                              //   subtitle: const Text(
                              //       "Just for testing. Not in final app."),
                              //   onTap: () async {
                              //     final confirm = await showDialog<bool>(
                              //       context: context,
                              //       builder: (context) => AlertDialog(
                              //         title: const Text("Confirm Deletion"),
                              //         content: const Text(
                              //             "Are you sure you want to delete your account? This action cannot be undone."),
                              //         actions: [
                              //           TextButton(
                              //             onPressed: () =>
                              //                 Navigator.of(context).pop(false),
                              //             child: const Text("Cancel"),
                              //           ),
                              //           TextButton(
                              //             onPressed: () =>
                              //                 Navigator.of(context).pop(true),
                              //             child: const Text("Delete",
                              //                 style:
                              //                     TextStyle(color: Colors.red)),
                              //           ),
                              //         ],
                              //       ),
                              //     );
                              //     if (confirm == true) {
                              //       final emailController =
                              //           TextEditingController();
                              //       final passwordController =
                              //           TextEditingController();

                              //       final credentialsConfirmed =
                              //           await showDialog<bool>(
                              //         context: context,
                              //         builder: (context) => AlertDialog(
                              //           title: const Text("Enter Credentials"),
                              //           content: Column(
                              //             mainAxisSize: MainAxisSize.min,
                              //             children: [
                              //               TextField(
                              //                 controller: emailController,
                              //                 decoration: const InputDecoration(
                              //                     labelText: "Email"),
                              //               ),
                              //               TextField(
                              //                 controller: passwordController,
                              //                 decoration: const InputDecoration(
                              //                     labelText: "Password"),
                              //                 obscureText: true,
                              //               ),
                              //             ],
                              //           ),
                              //           actions: [
                              //             TextButton(
                              //               onPressed: () =>
                              //                   Navigator.of(context)
                              //                       .pop(false),
                              //               child: const Text("Cancel"),
                              //             ),
                              //             TextButton(
                              //               onPressed: () =>
                              //                   Navigator.of(context).pop(true),
                              //               child: const Text("Confirm"),
                              //             ),
                              //           ],
                              //         ),
                              //       );

                              //       if (credentialsConfirmed == true) {
                              //         final email = emailController.text;
                              //         final password = passwordController.text;
                              //         try {
                              //           await ref
                              //               .read(
                              //                   authViewModelProvider.notifier)
                              //               .deleteAccount(
                              //                   context, email, password);
                              //         } catch (e) {
                              //           ScaffoldMessenger.of(context)
                              //               .showSnackBar(
                              //             SnackBar(
                              //                 content: Text(
                              //                     'Error reauthenticating user: $e')),
                              //           );
                              //         }
                              //       }
                              //     }
                              //   },
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            "About",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Card.outlined(
                          child: ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              // if (!kIsWeb &&
                              //     (defaultTargetPlatform ==
                              //             TargetPlatform.iOS ||
                              //         defaultTargetPlatform ==
                              //             TargetPlatform.android))
                              //   ListTile(
                              //     leading: const Icon(Icons.favorite_border),
                              //     title: Text(subscriptionStatus == "Active"
                              //         ? "Thank You For Supporting Us!"
                              //         : "Support Us And Remove Ads"),
                              //     onTap: subscriptionStatus == "Active"
                              //         ? null
                              //         : () async {
                              //             _showSupportUsModal(context, ref);
                              //           },
                              //   )
                              // else
                              // ListTile(
                              //   leading: const Icon(Icons.favorite_border),
                              //   title: Text(
                              //     subscriptionStatus == "Active"
                              //         ? "Thank you for supporting us!"
                              //         : "Support us and remove ads",
                              //   ),
                              //   subtitle: Text(
                              //     subscriptionStatus == "Active"
                              //         ? "You can manage your subscription on the mobile app"
                              //         : "Remove ads and support the developer by subscribing on the mobile app",
                              //   ),
                              // ),
                              Divider(
                                color: Colors.black.withOpacity(0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                leading: const Icon(Icons.help_outline),
                                title: const Text("Wiki"),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  launchUrl(
                                    Uri.parse(
                                      'https://wiki.shelterpartner.org',
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                color: Colors.black.withOpacity(0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                leading: const Icon(Icons.info_outline),
                                title: const Text("Acknowledgements"),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  context.push('/settings/acknowledgements');
                                },
                              ),
                              Divider(
                                color: Colors.black.withOpacity(0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.numbers,
                                  color: Colors.grey,
                                ),
                                title: Text(
                                  _version,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Divider(
                                color: Colors.black.withOpacity(0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              const ListTile(
                                leading: Icon(Icons.pets, color: Colors.grey),
                                title: Text(
                                  "Dedicated to Aslan",
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Divider(
                                color: Colors.black.withOpacity(0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.description,
                                            color: Colors.black87),
                                        SizedBox(width: 10),
                                        Text(
                                          'Release Notes',
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (_releases.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child:
                                            Text("Fetching release notes..."),
                                      )
                                    else ...[
                                      // Show only the most recent release if not showing previous
                                      ReleaseNotes(
                                        releases: _releases,
                                        showPreviousVersions:
                                            _showPreviousVersions,
                                        expandedReleases: _expandedReleases,
                                        onToggleExpand: (index) {
                                          setState(() {
                                            if (_expandedReleases
                                                .contains(index)) {
                                              _expandedReleases.remove(index);
                                            } else {
                                              _expandedReleases.add(index);
                                            }
                                          });
                                        },
                                        onToggleShowPrevious: () {
                                          setState(() {
                                            _showPreviousVersions =
                                                !_showPreviousVersions;
                                            if (!_showPreviousVersions) {
                                              _expandedReleases = {0};
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ],
                                ),
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
          ),
        ),
      ),
    );
  }
}

Future<List<GitHubRelease>> fetchFilteredReleases() async {
  final response = await http.get(
    Uri.parse(
        'https://api.github.com/repos/ShelterPartner/ShelterPartner/releases'),
  );

  if (response.statusCode == 200) {
    try {
      List<dynamic> jsonList = jsonDecode(response.body);
      final releases = jsonList
          .map((json) {
            try {
              return GitHubRelease.fromJson(json);
            } catch (_) {
              return null;
            }
          })
          .whereType<GitHubRelease>()
          .toList();
      return releases..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    } catch (e) {
      print('Failed to decode JSON');
      throw Exception('Invalid JSON: $e');
    }
  } else {
    throw Exception('Failed to fetch releases');
  }
}
