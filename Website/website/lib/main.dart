import 'package:flutter/material.dart';
import 'package:website/pages/home_page.dart';
import 'package:website/pages/wiki_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Website',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Default primary color
        brightness: Brightness.light, // Light theme
        scaffoldBackgroundColor: Colors.white,
        
        // You can add more theme properties here
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/wiki': (context) => const WikiPage(),
      },
    );
  }
}
