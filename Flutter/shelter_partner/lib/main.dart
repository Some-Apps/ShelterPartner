import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shelter_partner/auth/auth.dart';
import 'package:shelter_partner/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
        home: AuthPage()
        );
  }
}