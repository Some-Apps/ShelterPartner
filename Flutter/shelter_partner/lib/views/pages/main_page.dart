import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';

class MainPage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);
    final volunteerSettingsAsyncValue = ref.watch(volunteersViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    if (authState.status == AuthStatus.loading ||
        volunteerSettingsAsyncValue.isLoading) {
      // Show a loading indicator while checking authentication status or loading volunteer settings
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (authState.status == AuthStatus.unauthenticated) {
      // If the user is not authenticated, redirect to the login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    } else if (authState.status == AuthStatus.authenticated) {
      // User is authenticated; proceed with the main content

      if (appUser == null) {
        return const Scaffold(
          body: Center(child: Text('Error: User data not available')),
        );
      }

      if (volunteerSettingsAsyncValue.hasError) {
        return Scaffold(
          body: Center(
            child: Text(
              'Error: ${volunteerSettingsAsyncValue.error.toString()}',
            ),
          ),
        );
      }

      final volunteerSettings = volunteerSettingsAsyncValue.value!;

      // Modes that act like Volunteer
      Set<String> volunteerModes = {
        'Enrichment',
        'Visitor',
        'Enrichment & Visitor',
      };

      // Define the navigation items and visible indexes
      List<BottomNavigationBarItem> items = [];
      List<int> visibleIndexes = [];

      if (appUser.type == 'admin') {
        if (appUser.accountSettings?.mode == 'Admin') {
          items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Enrichment',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Visitors',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: 'Volunteers',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ];
          visibleIndexes = [0, 1, 2, 3];
        } else if (appUser.accountSettings?.mode == 'Enrichment') {
          items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Enrichment',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.door_front_door_outlined),
              label: 'Switch To Admin',
            ),
          ];
          visibleIndexes = [0, 4]; // Indexes corresponding to the branches
        } else if (appUser.accountSettings?.mode == 'Visitor') {
          items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Visitors',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.door_front_door_outlined),
              label: 'Switch To Admin',
            ),
          ];
          visibleIndexes = [1, 4];
        } else if (appUser.accountSettings?.mode == 'Enrichment & Visitor') {
          items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Enrichment',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Visitors',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.door_front_door_outlined),
              label: 'Switch To Admin',
            ),
          ];
          visibleIndexes = [0, 1, 4];
        } else {
          // Default to volunteer items
          items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Enrichment',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ];
          visibleIndexes = [0, 3];
        }
      } else {
        // Non-admin users (e.g., volunteers) can access 'Animals' and 'Settings'
        items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Enrichment',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
        visibleIndexes = [0, 3];
      }

      // Map the visible indexes to their positions in the items list
      Map<int, int> indexMap = {};
      for (int i = 0; i < visibleIndexes.length; i++) {
        indexMap[visibleIndexes[i]] = i;
      }

      int currentIndex = indexMap[navigationShell.currentIndex] ?? 0;

      // Determine if user is a volunteer
      bool isVolunteerUser = appUser.type == 'volunteer';
      bool isGeofenceEnabled =
          volunteerSettings.volunteerSettings.geofence?.isEnabled ?? false;

      // Get the geofence status
      final geofenceStatusAsyncValue = ref.watch(geofenceStatusProvider);

      return Scaffold(
        body: Builder(
          builder: (context) {
            // Check if the user is a volunteer and geofencing is enabled
            if (isVolunteerUser && isGeofenceEnabled) {
              // Determine the index for the 'Animals' tab
              int enrichmentBranchIndex =
                  0; // Assuming 'Animals' branch index is 0
              int enrichmentTabIndex = visibleIndexes.indexOf(
                enrichmentBranchIndex,
              );

              if (currentIndex == enrichmentTabIndex) {
                // Use the geofence status to determine what to display
                return geofenceStatusAsyncValue.when(
                  data: (isWithinGeofence) {
                    if (isWithinGeofence) {
                      // User is within geofence, show the EnrichmentPage
                      return navigationShell;
                    } else {
                      // User is outside geofence, show the restriction message
                      return const Center(
                        child: Text(
                          'Account georestricted: you must be at your shelter to use the app',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error: ${err.toString()}')),
                );
              } else {
                // For other tabs, show the normal content
                return navigationShell;
              }
            } else {
              // User is not a volunteer or geofencing is not enabled
              return navigationShell;
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          currentIndex: currentIndex,
          onTap: (index) {
            int branchIndex = visibleIndexes[index];
            if (navigationShell.currentIndex == branchIndex) {
              // User tapped the current tab again; reset navigation stack
              navigationShell.goBranch(branchIndex, initialLocation: true);

              // If the Enrichment tab is tapped again
              if (branchIndex == 0) {
                // Assuming EnrichmentPage is at index 0
                // Set scrollToTopProvider to true
                ref.read(scrollToTopProvider.notifier).state = true;
              }
              if (branchIndex == 1) {
                // Assuming VisitorsPage is at index 1
                // Set scrollToTopProvider to true
                ref.read(scrollToTopProviderVisitors.notifier).state = true;
              }
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

// providers/geofence_status_provider.dart

final geofenceStatusProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final appUser = ref.watch(appUserProvider);

  if (appUser == null) {
    yield false; // User data not available
    return;
  }

  bool isVolunteerUser = appUser.type == 'volunteer';

  // Wait for volunteerSettings to be available
  final volunteerSettingsAsyncValue = ref.watch(volunteersViewModelProvider);

  if (volunteerSettingsAsyncValue.isLoading) {
    // Yield false to indicate that geofence is not accessible yet
    yield false;
    // Alternatively, you can yield null and handle it in the UI
    return;
  } else if (volunteerSettingsAsyncValue.hasError) {
    // Handle the error case
    yield false;
    return;
  }

  final volunteerSettings = volunteerSettingsAsyncValue.value!;
  bool isGeofenceEnabled =
      volunteerSettings.volunteerSettings.geofence?.isEnabled ?? false;

  if (!isVolunteerUser || !isGeofenceEnabled) {
    yield true; // No geofence restrictions
    return;
  }

  final geofence = volunteerSettings.volunteerSettings.geofence!;

  // Check and request location permissions
  LocationPermission permission;
  try {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permissions are denied, cannot proceed
        yield false;
        return;
      }
    }
  } catch (e) {
    // Handle exceptions (e.g., if location services are disabled)
    yield false;
    return;
  }

  // Check if location services are enabled
  bool serviceEnabled;
  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      yield false;
      return;
    }
  } catch (e) {
    // Handle exceptions
    yield false;
    return;
  }

  // Get initial position with timeout
  Position initialPosition;
  try {
    initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    // Handle timeout or other exceptions
    yield false;
    return;
  }

  // Calculate distance to geofence center
  double distanceInMeters = Geolocator.distanceBetween(
    geofence.location.latitude,
    geofence.location.longitude,
    initialPosition.latitude,
    initialPosition.longitude,
  );

  // Check if within geofence radius
  bool isWithinGeofence = distanceInMeters <= geofence.radius;

  // Emit the initial geofence status
  yield isWithinGeofence;

  // Listen to position updates
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  final positionStream = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  );

  await for (final position in positionStream) {
    // Calculate distance to geofence center
    double distanceInMeters = Geolocator.distanceBetween(
      geofence.location.latitude,
      geofence.location.longitude,
      position.latitude,
      position.longitude,
    );

    // Check if within geofence radius
    bool isWithinGeofence = distanceInMeters <= geofence.radius;

    // Emit the geofence status
    yield isWithinGeofence;
  }
});

// providers/scroll_to_top_provider.dart

final scrollToTopProvider = StateProvider<bool>((ref) => false);
final scrollToTopProviderVisitors = StateProvider<bool>((ref) => false);
