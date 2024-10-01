import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/views/pages/volunteer_page.dart';
import '../components/main_tab_bar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainPage extends StatefulWidget {
  final AppUser? appUser;  // User object passed from authentication

  MainPage({required this.appUser});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // List of pages, we no longer need to explicitly pass the user here
  List<Widget> get _pages => [
    VolunteerPage(),  // No need to pass shelterId explicitly
    VisitorPage(),
    SettingsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Provider<AppUser?>.value(  // Provide the user object globally within MainPage
      value: widget.appUser,
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: MainTabBarView(
          currentIndex: _currentIndex,
          onTabSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
