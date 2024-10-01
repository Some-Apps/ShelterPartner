import 'package:flutter/material.dart';
import 'package:shelter_partner/views/pages/settings_page.dart';
import 'package:shelter_partner/views/pages/visitor_page.dart';
import 'package:shelter_partner/views/pages/volunteer_page.dart';
import '../components/main_tab_bar_view.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    VolunteerPage(),
    VisitorPage(),
    SettingsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: MainTabBarView(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
