import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class MainPage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    if (authState.status == AuthStatus.loading) {
      // Show a loading indicator while checking authentication status
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (authState.status == AuthStatus.unauthenticated) {
      // If the user is not authenticated, redirect to the login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    } else if (authState.status == AuthStatus.authenticated) {
      // User is authenticated; proceed with the main content
      final appUser = authState.user!;
      final isAdmin = appUser.type == "admin";

      // Modes that act like Volunteer
      Set<String> volunteerModes = {
        'Volunteer',
        'Visitor',
        'Volunteer & Visitor'
      };

      // Define the navigation items and visible indexes
      List<BottomNavigationBarItem> items = [];
      List<int> visibleIndexes = [];

      if (isAdmin) {
        if (appUser.deviceSettings!.mode == 'Admin') {
          items = [
            const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.volunteer_activism), label: 'Volunteers'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ];
          visibleIndexes = [0, 1, 2, 3];
        } else if (appUser.deviceSettings!.mode == 'Volunteer') {
          items = [
            const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.door_front_door_outlined), label: 'Switch To Admin'),
          ];
          visibleIndexes = [0, 4]; // Indexes corresponding to the branches
        } else if (appUser.deviceSettings!.mode == 'Visitor') {
          items = [
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.door_front_door_outlined), label: 'Switch To Admin'),
          ];
          visibleIndexes = [1, 4];
        } else if (appUser.deviceSettings!.mode == 'Volunteer & Visitor') {
          items = [
            const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.door_front_door_outlined), label: 'Switch To Admin'),
          ];
          visibleIndexes = [0, 1, 4];
        } else {
          // Default to admin items
          items = [
            const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.volunteer_activism), label: 'Volunteers'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ];
          visibleIndexes = [0, 1, 2, 3];
        }
      } else {
        // Non-admin users can access 'Animals' and 'Settings'
        items = [
          const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ];
        visibleIndexes = [0, 3];
      }

      // Map the visible indexes to their positions in the items list
      Map<int, int> indexMap = {};
      for (int i = 0; i < visibleIndexes.length; i++) {
        indexMap[visibleIndexes[i]] = i;
      }

      int currentIndex = indexMap[navigationShell.currentIndex] ?? 0;

      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          currentIndex: currentIndex,
          onTap: (index) {
            int branchIndex = visibleIndexes[index];
            if (navigationShell.currentIndex == branchIndex) {
              // User tapped the current tab again; reset navigation stack
              navigationShell.goBranch(
                branchIndex,
                initialLocation: true,
              );
            } else {
              navigationShell.goBranch(branchIndex);
            }
          },
          items: items,
        ),
      );
    } else if (authState.status == AuthStatus.error) {
      // Display error message if authentication fails
      return Scaffold(
        body: Center(child: Text('Error: ${authState.errorMessage}')),
      );
    } else {
      // Default case (should not reach here)
      return const SizedBox.shrink();
    }
  }
}
