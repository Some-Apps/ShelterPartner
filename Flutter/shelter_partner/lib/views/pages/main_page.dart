import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';

class MainPage extends ConsumerWidget {
  final Widget child;
  final String currentLocation; // Pass the location as a parameter

  const MainPage({
    super.key,
    required this.child,
    required this.currentLocation, // Initialize the location
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider); // Fetch appUser from provider

    if (appUser == null) {
      return const Center(child: Text("User not found"));
    }

    final isAdmin = appUser.type == "admin";

    // Modes that act like Volunteer
    Set<String> volunteerModes = {'Volunteer', 'Visitor', 'Volunteer & Visitor'};

    // Define the items and routes
    const adminItems = [
      BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
      BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Volunteers'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
    ];

    const adminRoutes = ['/animals', '/visitors', '/volunteers', '/settings'];

    const volunteerItems = [
      BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
      BottomNavigationBarItem(icon: Icon(Icons.door_front_door_outlined), label: 'Switch To Admin'),
    ];

    const volunteerRoutes = ['/animals', '/switch-to-admin'];

    const visitorItems = [
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
      BottomNavigationBarItem(icon: Icon(Icons.door_front_door_outlined), label: 'Switch To Admin'),
    ];

    const visitorRoutes = ['/visitors', '/switch-to-admin'];

    const volunteerAndVisitorItems = [
      BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
      BottomNavigationBarItem(icon: Icon(Icons.door_front_door_outlined), label: 'Switch To Admin'),
    ];

    const volunteerAndVisitorRoutes = ['/animals', '/visitors', '/switch-to-admin'];

    List<BottomNavigationBarItem> items;
    List<String> routes;

    if (isAdmin) {
      if (appUser.deviceSettings.mode == 'Admin') {
        items = adminItems;
        routes = adminRoutes;
      } else if (appUser.deviceSettings.mode == 'Volunteer') {
        items = volunteerItems;
        routes = volunteerRoutes;
      } else if (appUser.deviceSettings.mode == 'Visitor') {
        items = visitorItems;
        routes = visitorRoutes;
      } else if (appUser.deviceSettings.mode == 'Volunteer & Visitor') {
        items = volunteerAndVisitorItems;
        routes = volunteerAndVisitorRoutes;
      } else {
        // Default to admin items
        items = adminItems;
        routes = adminRoutes;
      }
    } else {
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
        const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ];
      routes = ['/animals', '/settings'];
    }

    // Determine currentIndex based on currentLocation
    int currentIndex = routes.indexWhere((route) => currentLocation.startsWith(route));
    if (currentIndex == -1) {
      currentIndex = 0; // Default to first tab
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        currentIndex: currentIndex,
        onTap: (index) {
          context.go(routes[index]);
        },
        items: items,
      ),
    );
  }
}
