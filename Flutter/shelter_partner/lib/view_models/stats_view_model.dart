import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/models/filter_condition.dart';
import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/repositories/animals_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:rxdart/rxdart.dart';

class StatsViewModel extends StateNotifier<Map<String, List<Animal>>> {
  final EnrichmentRepository _repository;
  final Ref ref;

  StreamSubscription<void>? _animalsSubscription;

  StatsViewModel(this._repository, this.ref)
      : super({'cats': [], 'dogs': []}) {

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

  // fetch animals

  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel(); // Cancel any existing subscription

    // Fetch animals stream
    final animalsStream = _repository.fetchAnimals(shelterID);

    // Fetch account settings stream (filter)
    final accountSettingsStream = ref.watch(accountSettingsViewModelProvider);

    // Combine the streams
    _animalsSubscription = animalsStream.listen((animals) {

    });
  }


  

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    super.dispose();
  }

}

final enrichmentViewModelProvider =
    StateNotifierProvider<StatsViewModel, Map<String, List<Animal>>>((ref) {
  final repository =
      ref.watch(enrichmentRepositoryProvider); // Access the repository
  return StatsViewModel(repository, ref); // Pass the repository and ref
});
