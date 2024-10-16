import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

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

    // if (appUser == null) {
    //   return const Center(child: Text("User not found"));
    // }

    // Use the passed currentLocation to determine the active tab
    int currentIndex;
    if (currentLocation.startsWith('/animals')) {
      currentIndex = 0;
    } else if (currentLocation.startsWith('/visitors')) {
      currentIndex = 1;
    } else if (currentLocation.startsWith('/volunteers')) {
      currentIndex = 2;
    } else if (currentLocation.startsWith('/settings')) {
      currentIndex = 3;
    } else {
      currentIndex = 0; // Default to the first tab if unknown
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
          switch (index) {
            case 0:
              context.go('/animals'); // Use context.go() to replace the route
              break;
            case 1:
              context.go('/visitors');
              break;
            case 2:
              context.go('/volunteers');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
          BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism), label: 'Volunteers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
