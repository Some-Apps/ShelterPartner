import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/stats_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class StatsViewModel extends StateNotifier<Map<String, dynamic>> {
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
      final newStats = _groupByTimeframe(animals);
      final changes = _detectChanges(state, newStats);

      state = {
        ...newStats,
        "lastApiSyncTime": DateTime.now().toIso8601String(),
        "recentChanges": changes,
      };

      ref.read(lastSyncProvider.notifier).state = DateTime.now();
      ref.read(recentChangesProvider.notifier).state = changes;
    });
  }

  Map<String, Map<String, Map<String, int>>> _groupByTimeframe(
      List<Animal> animals) {
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
      if (animal.logs.isNotEmpty) {
        final duration =
            now.difference(animal.logs.last.startTime.toDate()).inHours;
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
        speciesData[interval]?[species] =
            (speciesData[interval]?[species] ?? 0) + 1;

        final colorString = (animal.symbolColor ?? '').toLowerCase();
        if (colorString.isNotEmpty) {
          colorData[interval]?[colorString] =
              (colorData[interval]?[colorString] ?? 0) + 1;
        }
      }
    }

    return {
      'Species': speciesData,
      'Color': colorData,
    };
  }

  List<String> _detectChanges(Map<String, dynamic> oldStats,
      Map<String, Map<String, Map<String, int>>> newStats) {
    int addedCount = 0;
    int removedCount = 0;
    String? lastAdded;
    String? lastRemoved;

    for (var category in newStats.keys) {
      if (category != 'Species') continue;

      for (var timeframe in newStats[category]!.keys) {
        for (var key in newStats[category]![timeframe]!.keys) {
          int oldValue = oldStats[category]?[timeframe]?[key] ?? 0;
          int newValue = newStats[category]![timeframe]![key]!;

          if (newValue > oldValue) {
            addedCount += (newValue - oldValue);
            lastAdded = key;
          } else if (newValue < oldValue) {
            removedCount += (oldValue - newValue);
            lastRemoved = key;
          }
        }
      }
    }

    if (addedCount == 1 && removedCount == 0) {
      return ["A new $lastAdded was added to the shelter"];
    } else if (removedCount == 1 && addedCount == 0) {
      return ["A $lastRemoved was removed from the shelter"];
    } else if (addedCount > 1 || removedCount > 1) {
      return ["API called to sync"];
    }

    return [];
  }

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    super.dispose();
  }
}

final statsViewModelProvider =
    StateNotifierProvider<StatsViewModel, Map<String, dynamic>>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return StatsViewModel(repository, ref);
});

final categoryProvider = StateProvider<String?>((ref) => null);
final lastSyncProvider = StateProvider<DateTime?>((ref) => null);
final recentChangesProvider = StateProvider<List<String>>((ref) => []);
