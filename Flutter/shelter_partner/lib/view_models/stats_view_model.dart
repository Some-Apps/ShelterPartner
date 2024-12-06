import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/stats_repository.dart';
import 'package:intl/intl.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class StatsViewModel extends StateNotifier<Map<String, Map<String, int>>> {
  final StatsRepository _repository;
  final Ref ref;

  StreamSubscription<void>? _animalsSubscription;

  StatsViewModel(this._repository, this.ref) : super({}) {
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
      // Clear stats when not authenticated
      state = {};
      _animalsSubscription?.cancel();
    }
  }

  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel(); // Cancel any existing subscription
    final animalsStream = _repository.fetchAnimals(shelterID);

    _animalsSubscription = animalsStream.listen((animals) {
      final counts = _groupByTimeframe(animals);
      state = counts; // Update state with grouped data
    });
  }

Map<String, Map<String, int>> _groupByTimeframe(List<Animal> animals) {
  final grouped = <String, Map<String, int>>{
    '<6 hours': {},
    '6-24 hours': {},
    '1-2 days': {},
    '3+ days': {},
  };

  final now = DateTime.now();

  for (final animal in animals) {
    if (animal.logs.last?.startTime != null) {
      final duration = now.difference(animal.logs.last!.startTime.toDate()).inHours;
      String interval;

      if (duration < 6) {
        interval = '<6 hours';
      } else if (duration < 24) {
        interval = '6-24 hours';
      } else if (duration < 48) {
        interval = '1-2 days';
      } else {
        interval = '3+ days';
      }

      final category = animal.species ?? 'cat'; // Handle null species

      // Ensure the category is initialized
      if (!grouped[interval]!.containsKey(category)) {
        grouped[interval]![category] = 0;
      }

      // Increment the count
      grouped[interval]![category] = grouped[interval]![category]! + 1;
    }
  }

  return grouped;
}

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    super.dispose();
  }
}

final statsViewModelProvider =
    StateNotifierProvider<StatsViewModel, Map<String, Map<String, int>>>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return StatsViewModel(repository, ref);
});

final categoryProvider = StateProvider<String?>((ref) => null);