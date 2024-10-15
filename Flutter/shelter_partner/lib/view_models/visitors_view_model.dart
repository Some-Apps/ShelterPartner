import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/visitors_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class VisitorsViewModel extends StateNotifier<Map<String, List<Animal>>> {
  final VisitorsRepository _repository;
  final Ref ref;

  StreamSubscription<List<Animal>>? _animalsSubscription;

  VisitorsViewModel(this._repository, this.ref)
      : super({'cats': [], 'dogs': []}) {
    // Listen to authentication state changes
    ref.listen<AuthState>(
      authViewModelProvider,
      (previous, next) {
        _onAuthStateChanged(next);
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

  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel(); // Cancel any existing subscription
    _animalsSubscription =
        _repository.fetchAnimals(shelterID).listen((animals) {
      final cats = animals.where((animal) => animal.species == 'cat').toList();
      final dogs = animals.where((animal) => animal.species == 'dog').toList();
      state = {'cats': cats, 'dogs': dogs};
    });
  }

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    super.dispose();
  }
}

// Create a provider for the VisitorsViewModel
final visitorsViewModelProvider =
    StateNotifierProvider<VisitorsViewModel, Map<String, List<Animal>>>((ref) {
  final repository =
      ref.watch(visitorsRepositoryProvider); // Access the repository
  return VisitorsViewModel(repository, ref); // Pass the repository and ref
});
