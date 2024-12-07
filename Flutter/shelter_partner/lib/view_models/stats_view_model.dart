import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/stats_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';



// The state now holds a map with two top-level keys: "Species" and "Color".
class StatsViewModel extends StateNotifier<Map<String, Map<String, Map<String, int>>>> {
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
      state = {};
      _animalsSubscription?.cancel();
    }
  }

  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel();
    final animalsStream = _repository.fetchAnimals(shelterID);

    _animalsSubscription = animalsStream.listen((animals) {
      final result = _groupByTimeframe(animals);
      state = result; 
    });
  }

  Map<String, Map<String, Map<String, int>>> _groupByTimeframe(List<Animal> animals) {
    final intervals = ['<6 hours', '6-24 hours', '1-2 days', '3+ days'];

    // Initialize species and color maps
    final speciesData = {
      '<6 hours': <String, int>{},
      '6-24 hours': <String, int>{},
      '1-2 days': <String, int>{},
      '3+ days': <String, int>{},
    };

    final colorData = {
      '<6 hours': <String, int>{},
      '6-24 hours': <String, int>{},
      '1-2 days': <String, int>{},
      '3+ days': <String, int>{},
    };

    final now = DateTime.now();

    for (final animal in animals) {
      if (animal.logs.isNotEmpty && animal.logs.last.startTime != null) {
        final duration = now.difference(animal.logs.last.startTime.toDate()).inHours;
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

        final species = animal.species ?? 'cat';
        speciesData[interval]?[species] = (speciesData[interval]?[species] ?? 0) + 1;

        final colorString = (animal.symbolColor ?? '').toLowerCase();
        if (colorString.isNotEmpty) {
          colorData[interval]?[colorString] = (colorData[interval]?[colorString] ?? 0) + 1;
        }
      }
    }

    return {
      'Species': speciesData,
      'Color': colorData,
    };
  }

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    super.dispose();
  }
}

final statsViewModelProvider =
    StateNotifierProvider<StatsViewModel, Map<String, Map<String, Map<String,int>>>>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return StatsViewModel(repository, ref);
});

final categoryProvider = StateProvider<String?>((ref) => null);
