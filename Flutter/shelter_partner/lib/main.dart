import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:shelter_partner/firebase_options.dart';
import 'package:json_theme_plus/json_theme_plus.dart';
import 'package:shelter_partner/views/pages/animals_page.dart';
import 'package:shelter_partner/views/pages/main_page.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  MyApp({super.key, required this.theme, required this.darktheme});

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
          pageBuilder: (context, state) => const MaterialPage(child: AnimalsPage()),
        ),
        GoRoute(
          path: '/visitors',
          pageBuilder: (context, state) => const MaterialPage(child: VisitorPage()),
        ),
        GoRoute(
          path: '/volunteers',
          pageBuilder: (context, state) => const MaterialPage(child: VolunteersPage()),
          routes: [
            GoRoute(
              path: 'details/:id',  // Dynamic route for volunteer details
              pageBuilder: (context, state) {
                final volunteerId = state.pathParameters['id'];
                return MaterialPage(
                  child: VolunteerDetailPage(id: volunteerId!),
                );
              },
            ),
            GoRoute(
              path: 'volunteer-settings',  // This is relative to '/volunteers'
              pageBuilder: (context, state) => const MaterialPage(child: VolunteerSettingsPage()),
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const MaterialPage(child: SettingsPage()),
        ),
      ],
    ),
  ],
);



}
