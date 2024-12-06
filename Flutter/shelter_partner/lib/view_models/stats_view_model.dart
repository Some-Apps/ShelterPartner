import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/stats_repository.dart';
import 'package:intl/intl.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class StatsViewModel extends StateNotifier<Map<String, int>> {
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

  Map<String, int> _groupByTimeframe(List<Animal> animals) {
  final grouped = <String, int>{
    '<1 day': 0,
    '1-2 days': 0,
    '3-5 days': 0,
    '6-7 days': 0,
    '8+ days': 0,
  };

  final now = DateTime.now();

  for (final animal in animals) {
    if (animal.logs.last?.startTime != null) {
      final duration = now.difference(animal.logs.last!.startTime.toDate()).inDays;

      if (duration < 1) {
        grouped['<1 day'] = grouped['<1 day']! + 1;
      } else if (duration < 3) {
        grouped['1-2 days'] = grouped['1-2 days']! + 1;
      } else if (duration < 6) {
        grouped['3-5 days'] = grouped['3-5 days']! + 1;
      } else if (duration < 8) {
        grouped['6-7 days'] = grouped['6-7 days']! + 1;
      } else {
        grouped['8+ days'] = grouped['8+ days']! + 1;
      }
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
    StateNotifierProvider<StatsViewModel, Map<String, int>>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return StatsViewModel(repository, ref);
});
