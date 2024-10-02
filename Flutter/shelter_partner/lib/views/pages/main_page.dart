import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/views/pages/volunteer_page.dart';
import '../components/main_tab_bar_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/app_user.dart'; // Assuming AppUser is the model you're working with
import 'package:shelter_partner/views/pages/volunteer_page.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/components/main_tab_bar_view.dart';

class MainPage extends StatefulWidget {
  final AppUser appUser;

  MainPage({required this.appUser});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Manage the current index locally
  int _currentIndex = 0;

  // List of pages
  final List<Widget> _pages = [
    VolunteerPage(),  // Add logic to pass appUser if needed
    VisitorPage(),    // Add logic to pass appUser if needed
    SettingsPage(),   // Add logic to pass appUser if needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],  // Show the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;  // Update the index on tab selection
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Volunteer'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitor'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
