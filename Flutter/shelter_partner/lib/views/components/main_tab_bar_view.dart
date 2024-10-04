import 'package:flutter/material.dart';

class MainTabBarView extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const MainTabBarView({super.key, 
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: 'Volunteer',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Visitor',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Settings',
        ),
      ],
    );
  }
}
