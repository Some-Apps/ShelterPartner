import 'package:flutter/foundation.dart';
import 'package:shelter_partner/html_stub.dart'
    if (dart.library.html) 'dart:html'
    as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/firebase_service.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/models/theme.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:shelter_partner/views/pages/acknowledgements_page.dart';
import 'package:shelter_partner/views/pages/enrichment_animal_detail_page.dart';
import 'package:shelter_partner/views/pages/enrichment_page.dart';
import 'package:shelter_partner/views/pages/api_keys_page.dart';
import 'package:shelter_partner/views/pages/array_modifier_page.dart';
import 'package:shelter_partner/views/pages/better_impact_page.dart';
import 'package:shelter_partner/views/pages/change-password-page.dart';
import 'package:shelter_partner/views/pages/account_settings_page.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
import 'package:shelter_partner/views/pages/scheduled_reports_page.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/pages/shelter_settings_page.dart';
import 'package:shelter_partner/views/pages/stats_page.dart';
import 'package:shelter_partner/views/pages/switch_to_admin_page.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/views/pages/volunteer_detail_page.dart';
import 'package:shelter_partner/views/pages/volunteer_settings_page.dart';
import 'package:shelter_partner/views/pages/volunteers_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isMobileWeb() {
    if (!kIsWeb) return false; // Only do UA checks in web builds
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('android');
  }

  bool isIosWeb() {
    if (!kIsWeb) return false;
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') || userAgent.contains('ipad');
  }

  bool isAndroidWeb() {
    if (!kIsWeb) return false;
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('android');
  }

  // If running on the web AND on a mobile browser, redirect:
  if (isMobileWeb()) {
    if (isIosWeb()) {
      // 1) Try to open via custom URI scheme (if your iOS app uses one)
      html.window.location.assign("myapp://");

      // 2) Fallback: if not installed, wait ~0.5s and open the App Store
      Future.delayed(const Duration(milliseconds: 500), () {
        html.window.location.assign(
          "https://apps.apple.com/us/app/6449749673", // Your iOS App Store link
        );
      });
      return; // Don’t proceed to runApp
    } else if (isAndroidWeb()) {
      // 1) Try to open via Android Intent URI scheme
      //    Replace "com.mycompany.myapp" with your package name
      html.window.location.assign(
        "intent://myapp/#Intent;scheme=myapp;package=me.jareddanieljones.HumaneSociety;end",
      );

      // 2) Fallback: if not installed, open Google Play Store
      Future.delayed(const Duration(milliseconds: 500), () {
        html.window.location.assign(
          "https://play.google.com/store/apps/details?id=me.jareddanieljones.HumaneSociety",
        );
      });
      return; // Don’t proceed to runApp
    }
  }

  final theme = lightTheme;

  final FirebaseService firebaseService = FirebaseService();
  await firebaseService.initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(ProviderScope(child: MyApp(theme: theme)));
}

class MyApp extends ConsumerWidget {
  final ThemeData theme;

  const MyApp({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider); // Watch the GoRouter provider

    return MaterialApp.router(
      routerConfig: goRouter,
      theme: theme,
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
          return '/enrichment'; // Redirect to the main page or your desired route
        }
      }

      // No need to redirect at this point.
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AuthPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainPage(navigationShell: navigationShell);
        },
        branches: [
          // Branch for the 'Enrichment' tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/enrichment',
                builder: (context, state) => const EnrichmentPage(),
                routes: [
                  GoRoute(
                    path: 'details',
                    builder: (context, state) {
                      final animal = state.extra as Animal;
                      return EnrichmentAnimalDetailPage(
                        initialAnimal: animal,
                        visitorPage: false,
                      );
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
                      return EnrichmentAnimalDetailPage(
                        initialAnimal: animal,
                        visitorPage: true,
                      );
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
                    path: "acknowledgements",
                    builder: (context, state) => const AcknowledgementsPage(),
                  ),
                  GoRoute(
                    path: "change-password",
                    builder: (context, state) => const ChangePasswordPage(),
                  ),
                  GoRoute(
                    path: "stats",
                    builder: (context, state) => const StatsPage(),
                  ),
                  GoRoute(
                    path: 'shelter-settings',
                    builder: (context, state) => const ShelterSettingsPage(),
                    routes: [
                      GoRoute(
                        path: 'scheduled-reports',
                        builder: (context, state) => const ScheduledReportsPage(
                          title: 'Scheduled Reports',
                          arrayKey: 'scheduledReports',
                        ),
                      ),
                      GoRoute(
                        path: 'cat-tags',
                        builder: (context, state) {
                          return const ArrayModifierPage(
                            title: 'Cat Tags',
                            arrayKey: 'catTags',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'dog-tags',
                        builder: (context, state) {
                          return const ArrayModifierPage(
                            title: 'Dog Tags',
                            arrayKey: 'dogTags',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'early-put-back-reasons',
                        builder: (context, state) {
                          return const ArrayModifierPage(
                            title: 'Early Put Back Reasons',
                            arrayKey: 'earlyPutBackReasons',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'let-out-types',
                        builder: (context, state) {
                          return const ArrayModifierPage(
                            title: 'Let Out Types',
                            arrayKey: 'letOutTypes',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'api-keys',
                        builder: (context, state) => const ApiKeysPage(
                          title: 'API Keys',
                          arrayKey: 'apiKeys',
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'account-settings',
                    builder: (context, state) => const AccountSettingsPage(),
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
