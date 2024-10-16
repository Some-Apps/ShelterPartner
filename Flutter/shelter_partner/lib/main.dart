import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/firebase_service.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:json_theme_plus/json_theme_plus.dart';
import 'package:shelter_partner/views/pages/animals_page.dart';
import 'package:shelter_partner/views/pages/api_keys_page.dart';
import 'package:shelter_partner/views/pages/array_modifier_page.dart';
import 'package:shelter_partner/views/pages/device_settings_page.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
import 'package:shelter_partner/views/pages/scheduled_reports_page.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/pages/shelter_settings_page.dart';
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
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const MaterialPage(child: AuthPage()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainPage(
            currentLocation: state.uri.toString(),
            child: child, // Pass the current location to MainPage
          );
        },
        routes: [
          GoRoute(
            path: '/animals',
            pageBuilder: (context, state) =>
                const MaterialPage(child: AnimalsPage()),
          ),
          GoRoute(
              path: '/visitors',
              pageBuilder: (context, state) =>
                  const MaterialPage(child: VisitorPage()),
              routes: [
                GoRoute(
                path:
                    'details', // No need for ':id' since we're passing the object directly
                pageBuilder: (context, state) {
                  final animal = state.extra
                      as Animal; // Cast extra to the appropriate type
                  return MaterialPage(
                    child: VisitorAnimalDetailPage(animal: animal),
                  );
                },
              ),
              ]),
          GoRoute(
            path: '/volunteers',
            pageBuilder: (context, state) =>
                const MaterialPage(child: VolunteersPage()),
            routes: [
              GoRoute(
                path:
                    'details', // No need for ':id' since we're passing the object directly
                pageBuilder: (context, state) {
                  final volunteer = state.extra
                      as Volunteer; // Cast extra to the appropriate type
                  return MaterialPage(
                    child: VolunteerDetailPage(volunteer: volunteer),
                  );
                },
              ),
              GoRoute(
                path: 'volunteer-settings', // This is relative to '/volunteers'
                pageBuilder: (context, state) =>
                    const MaterialPage(child: VolunteerSettingsPage()),
              ),
            ],
          ),
          GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  const MaterialPage(child: SettingsPage()),
              routes: [
                GoRoute(
                    path:
                        'shelter-settings', // This is relative to '/volunteers'
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: ShelterSettingsPage()),
                    routes: [
                      GoRoute(
                        path:
                            'scheduled-reports', // This is relative to '/volunteers'
                        pageBuilder: (context, state) => const MaterialPage(
                            child: ScheduledReportsPage(
                                title: 'Scheduled Reports',
                                arrayKey: 'scheduledReports')),
                      ),
                      GoRoute(
                        path: 'cat-tags', // This is relative to '/volunteers'
                        pageBuilder: (context, state) {
                          return const MaterialPage(
                            child: ArrayModifierPage(
                                title: 'Cat Tags', arrayKey: 'catTags'),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'dog-tags', // This is relative to '/volunteers'
                        pageBuilder: (context, state) {
                          return const MaterialPage(
                            child: ArrayModifierPage(
                                title: 'Dog Tags', arrayKey: 'dogTags'),
                          );
                        },
                      ),
                      GoRoute(
                        path:
                            'early-put-back-reasons', // This is relative to '/volunteers'
                        pageBuilder: (context, state) {
                          return const MaterialPage(
                            child: ArrayModifierPage(
                                title: 'Early Put Back Reasons',
                                arrayKey: 'earlyPutBackReasons'),
                          );
                        },
                      ),
                      GoRoute(
                        path:
                            'let-out-types', // This is relative to '/volunteers'
                        pageBuilder: (context, state) {
                          return const MaterialPage(
                            child: ArrayModifierPage(
                                title: 'Let Out Types',
                                arrayKey: 'letOutTypes'),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'api-keys', // This is relative to '/volunteers'
                        pageBuilder: (context, state) => const MaterialPage(
                            child: ApiKeysPage(
                                title: 'API Keys', arrayKey: 'apiKeys')),
                      ),
                    ]),
                GoRoute(
                  path: 'device-settings', // This is relative to '/volunteers'
                  pageBuilder: (context, state) =>
                      const MaterialPage(child: DeviceSettingsPage()),
                ),
              ]),
        ],
      ),
    ],
  );
}
