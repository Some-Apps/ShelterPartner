import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:shelter_partner/firebase_options.dart';
import 'package:json_theme_plus/json_theme_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeStr = await rootBundle.loadString('assets/appainter_theme.json');
  final themeJson = jsonDecode(themeStr);
  final theme = ThemeDecoder.decodeThemeData(themeJson) ?? ThemeData.light();

  final darkThemeStr = await rootBundle.loadString('assets/appainter_theme_dark.json');
  final darkThemeJson = jsonDecode(darkThemeStr);
  final darktheme = ThemeDecoder.decodeThemeData(darkThemeJson) ?? ThemeData.dark();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  runApp(ProviderScope(child: MyApp(theme: theme, darktheme: darktheme,)));
}

class MyApp extends StatelessWidget {
  final ThemeData theme;
  final ThemeData darktheme;

  const MyApp({super.key, required this.theme, required this.darktheme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      darkTheme: darktheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
        home: const AuthPage()
        );
  }
}