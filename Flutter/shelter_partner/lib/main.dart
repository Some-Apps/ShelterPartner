import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/firebase_service.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:json_theme_plus/json_theme_plus.dart';
import 'package:shelter_partner/views/pages/animals_animal_detail_page.dart';
import 'package:shelter_partner/views/pages/animals_page.dart';
import 'package:shelter_partner/views/pages/api_keys_page.dart';
import 'package:shelter_partner/views/pages/array_modifier_page.dart';
import 'package:shelter_partner/views/pages/device_settings_page.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
import 'package:shelter_partner/views/pages/scheduled_reports_page.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/pages/shelter_settings_page.dart';
import 'package:shelter_partner/views/pages/switch_to_admin_page.dart';
import 'package:shelter_partner/views/pages/visitor_animal_detail_page.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/views/pages/volunteer_detail_page.dart';
import 'package:shelter_partner/views/pages/volunteer_settings_page.dart';
import 'package:shelter_partner/views/pages/volunteers_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeStr = await rootBundle.loadString('assets/appainter_theme.json');
  final themeJson = jsonDecode(themeStr);
  final theme = ThemeDecoder.decodeThemeData(themeJson) ?? ThemeData.light();

  final darkThemeStr =
      await rootBundle.loadString('assets/appainter_theme_dark.json');
  final darkThemeJson = jsonDecode(darkThemeStr);
  final darktheme =
      ThemeDecoder.decodeThemeData(darkThemeJson) ?? ThemeData.dark();

  final FirebaseService firebaseService = FirebaseService();
  await firebaseService.initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  runApp(ProviderScope(
      child: MyApp(
    theme: theme,
    darktheme: darktheme,
  )));
}

class MyApp extends StatelessWidget {
  final ThemeData theme;
  final ThemeData darktheme;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseService firebaseService;

  MyApp({
    super.key,
    required this.theme,
    required this.darktheme,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseService? firebaseService,
  })  : firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance,
        firebaseService = firebaseService ?? FirebaseService();

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp.router(
      routerConfig: _router,
      theme: theme,
      darkTheme: darktheme,
      // themeMode: ThemeMode.system
      themeMode: ThemeMode
          .light, // Always use light mode - add dark mode later after release
      debugShowCheckedModeBanner: false,
    );
  }

  final GoRouter _router = GoRouter(
  initialLocation: '/animals',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainPage(
          navigationShell: navigationShell,
        );
      },
      branches: [
        // Branch for the 'Animals' tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/animals',
              builder: (context, state) => const AnimalsPage(),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (context, state) {
                    final animal = state.extra as Animal;
                    return AnimalsAnimalDetailPage(initialAnimal: animal);
                  },
                ),
                GoRoute(
                  path: 'main-filter',
                  builder: (context, state) {
                    final params = state.extra as FilterParameters?;
                    if (params == null) {
                      throw Exception('FilterParameters not provided');
                    }
                    return MainFilterPage(
                      title: params.title,
                      collection: params.collection,
                      documentID: params.documentID,
                      filterFieldPath: params.filterFieldPath,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch for the 'Visitors' tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/visitors',
              builder: (context, state) => const VisitorPage(),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (context, state) {
                    final animal = state.extra as Animal;
                    return VisitorAnimalDetailPage(animal: animal);
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch for the 'Volunteers' tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/volunteers',
              builder: (context, state) => const VolunteersPage(),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (context, state) {
                    final volunteer = state.extra as Volunteer;
                    return VolunteerDetailPage(volunteer: volunteer);
                  },
                ),
                GoRoute(
                  path: 'volunteer-settings',
                  builder: (context, state) =>
                      const VolunteerSettingsPage(),
                  routes: [
                    GoRoute(
                      path: 'main-filter',
                      builder: (context, state) {
                        final params = state.extra as FilterParameters?;
                        if (params == null) {
                          throw Exception('FilterParameters not provided');
                        }
                        return MainFilterPage(
                          title: params.title,
                          collection: params.collection,
                          documentID: params.documentID,
                          filterFieldPath: params.filterFieldPath,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Branch for the 'Settings' tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'shelter-settings',
                  builder: (context, state) =>
                      const ShelterSettingsPage(),
                  routes: [
                    GoRoute(
                      path: 'scheduled-reports',
                      builder: (context, state) =>
                          const ScheduledReportsPage(
                              title: 'Scheduled Reports',
                              arrayKey: 'scheduledReports'),
                    ),
                    GoRoute(
                      path: 'cat-tags',
                      builder: (context, state) {
                        return const ArrayModifierPage(
                            title: 'Cat Tags', arrayKey: 'catTags');
                      },
                    ),
                    GoRoute(
                      path: 'dog-tags',
                      builder: (context, state) {
                        return const ArrayModifierPage(
                            title: 'Dog Tags', arrayKey: 'dogTags');
                      },
                    ),
                    GoRoute(
                      path: 'early-put-back-reasons',
                      builder: (context, state) {
                        return const ArrayModifierPage(
                            title: 'Early Put Back Reasons',
                            arrayKey: 'earlyPutBackReasons');
                      },
                    ),
                    GoRoute(
                      path: 'let-out-types',
                      builder: (context, state) {
                        return const ArrayModifierPage(
                            title: 'Let Out Types',
                            arrayKey: 'letOutTypes');
                      },
                    ),
                    GoRoute(
                      path: 'api-keys',
                      builder: (context, state) => const ApiKeysPage(
                          title: 'API Keys', arrayKey: 'apiKeys'),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'device-settings',
                  builder: (context, state) =>
                      const DeviceSettingsPage(),
                  routes: [
                    GoRoute(
                      path: 'main-filter',
                      builder: (context, state) {
                        final params = state.extra as FilterParameters?;
                        if (params == null) {
                          throw Exception('FilterParameters not provided');
                        }
                        return MainFilterPage(
                          title: params.title,
                          collection: params.collection,
                          documentID: params.documentID,
                          filterFieldPath: params.filterFieldPath,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'visitor-filter',
                      builder: (context, state) {
                        final params = state.extra as FilterParameters?;
                        if (params == null) {
                          throw Exception('FilterParameters not provided');
                        }
                        return MainFilterPage(
                          title: params.title,
                          collection: params.collection,
                          documentID: params.documentID,
                          filterFieldPath: params.filterFieldPath,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Branch for 'Switch to Admin' or other tabs
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/switch-to-admin',
              builder: (context, state) =>
                  const SwitchToAdminPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

}
