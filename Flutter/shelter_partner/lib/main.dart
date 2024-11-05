import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/firebase_service.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:shelter_partner/views/pages/acknowledgements_page.dart';
import 'package:shelter_partner/views/pages/animals_animal_detail_page.dart';
import 'package:shelter_partner/views/pages/animals_page.dart';
import 'package:shelter_partner/views/pages/api_keys_page.dart';
import 'package:shelter_partner/views/pages/array_modifier_page.dart';
import 'package:shelter_partner/views/pages/better_impact_page.dart';
import 'package:shelter_partner/views/pages/device_settings_page.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
import 'package:shelter_partner/views/pages/scheduled_reports_page.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/pages/shelter_settings_page.dart';
import 'package:shelter_partner/views/pages/switch_to_admin_page.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/views/pages/volunteer_detail_page.dart';
import 'package:shelter_partner/views/pages/volunteer_settings_page.dart';
import 'package:shelter_partner/views/pages/volunteers_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Define themes directly in code
  final ThemeData theme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  primaryColor: const Color(0xff36618e),
  canvasColor: const Color(0xfff8f9ff),
  scaffoldBackgroundColor: const Color(0xfff8f9ff),
  cardColor: const Color(0xfff8f9ff),
  dividerColor: const Color(0x1f191c20),
  disabledColor: const Color(0x61000000),
  focusColor: const Color(0x1f000000),
  highlightColor: const Color(0x66bcbcbc),
  hintColor: const Color(0x99000000),
  hoverColor: const Color(0x0a000000),
  splashColor: const Color(0x66c8c8c8),
  shadowColor: const Color(0xff000000),
  secondaryHeaderColor: const Color(0xffe3f2fd),
  indicatorColor: Colors.white,
  unselectedWidgetColor: const Color(0x8a000000),
  visualDensity: VisualDensity.compact,



  // Color scheme based on JSON
  // colorScheme: const ColorScheme(
  //   brightness: Brightness.light,
  //   primary: Color(0xff36618e),
  //   onPrimary: Colors.white,
  //   primaryContainer: Color(0xffd1e4ff),
  //   onPrimaryContainer: Color(0xff001d36),
  //   secondary: Color(0xff535f70),
  //   onSecondary: Colors.white,
  //   secondaryContainer: Color(0xffd7e3f7),
  //   onSecondaryContainer: Color(0xff101c2b),
  //   tertiary: Color(0xff6b5778),
  //   onTertiary: Colors.white,
  //   tertiaryContainer: Color(0xfff2daff),
  //   onTertiaryContainer: Color(0xff251431),
  //   background: Color(0xfff8f9ff),
  //   onBackground: Color(0xff191c20),
  //   surface: Color(0xfff8f9ff),
  //   onSurface: Color(0xff191c20),
  //   error: Color(0xffba1a1a),
  //   onError: Colors.white,
  //   errorContainer: Color(0xffffdad6),
  //   onErrorContainer: Color(0xff410002),
  //   outline: Color(0xff73777f),
  //   shadow: Color(0xff000000),
  //   surfaceTint: Color(0xff36618e),
  // ),

  // Icon theme
  iconTheme: const IconThemeData(color: Color(0xdd000000)),
  primaryIconTheme: const IconThemeData(color: Colors.white),

  // Text themes
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xff191c20),
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      color: Color(0xff191c20),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      color: Color(0xff191c20),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    displayLarge: TextStyle(
      color: Color(0xff191c20),
      fontSize: 96,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
    ),
    displayMedium: TextStyle(
      color: Color(0xff191c20),
      fontSize: 60,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      color: Color(0xff191c20),
      fontSize: 48,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      color: Color(0xff191c20),
      fontSize: 40,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    headlineMedium: TextStyle(
      color: Color(0xff191c20),
      fontSize: 34,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    headlineSmall: TextStyle(
      color: Color(0xff191c20),
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      color: Color(0xff191c20),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
    ),
    labelMedium: TextStyle(
      color: Color(0xff191c20),
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
    ),
    labelSmall: TextStyle(
      color: Color(0xff191c20),
      fontSize: 10,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
    ),
    titleLarge: TextStyle(
      color: Color(0xff191c20),
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleMedium: TextStyle(
      color: Color(0xff191c20),
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      color: Color(0xff191c20),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  ),

  // Button theme
  buttonTheme: const ButtonThemeData(
    alignedDropdown: false,
    height: 36,
    minWidth: 88,
    layoutBehavior: ButtonBarLayoutBehavior.padded,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
  ),

  // Input decoration theme
  inputDecorationTheme: const InputDecorationTheme(
    alignLabelWithHint: false,
    filled: false,
    floatingLabelAlignment: FloatingLabelAlignment.start,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    isCollapsed: false,
    isDense: false,
  ),

  // Typography
  typography: Typography.material2021(platform: TargetPlatform.macOS),
);


  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    // Additional dark theme customization here
  );

  final FirebaseService firebaseService = FirebaseService();
  await firebaseService.initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(ProviderScope(
      child: MyApp(
    theme: theme,
    darkTheme: darkTheme,
  )));
}

class MyApp extends ConsumerWidget {
  final ThemeData theme;
  final ThemeData darkTheme;

  const MyApp({
    super.key,
    required this.theme,
    required this.darkTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider); // Watch the GoRouter provider

    return MaterialApp.router(
      routerConfig: goRouter,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light, // Set your desired theme mode
      debugShowCheckedModeBanner: false,
    );
  }
}


// Create the AuthStateChangeNotifier
class AuthStateChangeNotifier extends ChangeNotifier {
  late final ProviderSubscription _subscription;

  AuthStateChangeNotifier(Ref ref) {
    // Listen to the authViewModelProvider changes
    _subscription = ref.listen<AuthState>(authViewModelProvider, (_, __) {
      // Whenever auth state changes, notify listeners
      notifyListeners();
    });
  }

  @override
  void dispose() {
    // Cancel the subscription when this notifier is disposed
    _subscription.close();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  // Create an instance of AuthStateChangeNotifier
  final authStateChangeNotifier = AuthStateChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authStateChangeNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.uri.toString() == '/';

      if (!isLoggedIn) {
        // If the user is not logged in, they need to go to the login page.
        return isLoggingIn ? null : '/';
      } else {
        // If the user is logged in and tries to access the login page, prevent it.
        if (isLoggingIn) {
          return '/animals'; // Redirect to the main page or your desired route
        }
      }

      // No need to redirect at this point.
      return null;
    },
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
                      return AnimalsAnimalDetailPage(
                          initialAnimal: animal, visitorPage: false);
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
                      return AnimalsAnimalDetailPage(
                          initialAnimal: animal, visitorPage: true);
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
                    builder: (context, state) => const VolunteerSettingsPage(),
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
                  GoRoute(
                    path: "better-impact",
                    builder: (context, state) => const BetterImpactPage(),
                  )
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
                  path: "acknowledgements",
                  builder: (context, state) => const AcknowledgementsPage(),
                ),
                  GoRoute(
                    path: 'shelter-settings',
                    builder: (context, state) => const ShelterSettingsPage(),
                    routes: [
                      GoRoute(
                        path: 'scheduled-reports',
                        builder: (context, state) => const ScheduledReportsPage(
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
                              title: 'Let Out Types', arrayKey: 'letOutTypes');
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
                    builder: (context, state) => const DeviceSettingsPage(),
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
                builder: (context, state) => const SwitchToAdminPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
