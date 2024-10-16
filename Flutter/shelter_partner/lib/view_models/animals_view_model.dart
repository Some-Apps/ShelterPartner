import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/visitors_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';


class AnimalsViewModel extends StateNotifier<Map<String, List<Animal>>> {
  final VisitorsRepository _repository;
  final Ref ref;

  StreamSubscription<List<Animal>>? _animalsSubscription;

  AnimalsViewModel(this._repository, this.ref)
      : super({'cats': [], 'dogs': []}) {
    // Listen to authentication state changes
    ref.listen<AuthState>(
      authViewModelProvider,
      (previous, next) {
        _onAuthStateChanged(next);
      },
    );
    ref.listen<AsyncValue<AppUser?>>(
      deviceSettingsViewModelProvider,
      (previous, next) {
        _sortAnimals();
      },
    );

    // Immediately check the current auth state
    final authState = ref.read(authViewModelProvider);
    _onAuthStateChanged(authState);
  }

  void _onAuthStateChanged(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      final shelterID = authState.user?.shelterId;
      if (shelterID != null) {
        fetchAnimals(shelterID: shelterID);
      }
    } else {
      // Clear animals when not authenticated
      state = {'cats': [], 'dogs': []};
      _animalsSubscription?.cancel();
    }
  }

  void _sortAnimals() {
  final deviceSettingsAsync = ref.read(deviceSettingsViewModelProvider);
  
  deviceSettingsAsync.whenData((appUser) {
    final visitorSort = appUser?.deviceSettings.visitorSort ?? 'Alphabetical';

    // Add this debug print to verify the sorting method being used
    print('Sorting by: $visitorSort');

    final sortedState = <String, List<Animal>>{};

    state.forEach((species, animalsList) {
      final sortedList = List<Animal>.from(animalsList);

      if (visitorSort == 'Alphabetical') {
        sortedList.sort((a, b) => a.name.compareTo(b.name));
        print('Sorted alphabetically');
      } else if (visitorSort == 'Location') {
        sortedList.sort((a, b) => a.location.compareTo(b.location));
        print('Sorted by intake date');
      }

      sortedState[species] = sortedList;
    });

    // Add this to verify if the sorting happens as expected
    sortedState.forEach((species, animalsList) {
      print('$species sorted list:');
      for (var animal in animalsList) {
        print(animal.name);
      }
    });

    state = sortedState;
  });
}


  // Modify fetchAnimals to call _sortAnimals after updating state
  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel(); // Cancel any existing subscription
    _animalsSubscription =
        _repository.fetchAnimals(shelterID).listen((animals) {
      final cats = animals.where((animal) => animal.species == 'cat').toList();
      final dogs = animals.where((animal) => animal.species == 'dog').toList();

      state = {'cats': cats, 'dogs': dogs};

      // Sort the animals after fetching
      _sortAnimals();
    });
  }

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    super.dispose();
  }
}

// Create a provider for the VisitorsViewModel
final animalsViewModelProvider =
    StateNotifierProvider<AnimalsViewModel, Map<String, List<Animal>>>((ref) {
  final repository =
      ref.watch(visitorsRepositoryProvider); // Access the repository
  return AnimalsViewModel(repository, ref); // Pass the repository and ref
});
