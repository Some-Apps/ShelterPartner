import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/stats_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class StatsViewModel extends StateNotifier<Map<String, dynamic>> {
  final StatsRepository _repository;
  final Ref ref;

  StreamSubscription<void>? _animalsSubscription;
  StreamSubscription<String>? _emailSyncSubscription;
  StreamSubscription<Map<String, dynamic>>? _syncDataSubscription;
  bool _isInitialLoad = true;

  StatsViewModel(this._repository, this.ref) : super({}) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      _onAuthStateChanged(next);
    });

    final authState = ref.read(authViewModelProvider);
    _onAuthStateChanged(authState);
  }

  void _onAuthStateChanged(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      final shelterID = authState.user?.shelterId;
      if (shelterID != null) {
        _isInitialLoad = true; // Reset initial load flag
        fetchAnimals(shelterID: shelterID);
        _fetchLastEmailSyncTime(shelterID);
        _fetchLastSyncData(shelterID);
      }
    } else {
      state = {};
      _isInitialLoad = true;
      _animalsSubscription?.cancel();
      _emailSyncSubscription?.cancel();
      _syncDataSubscription?.cancel();
    }
  }

  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel();
    final animalsStream = _repository.fetchAnimals(shelterID);

    _animalsSubscription = animalsStream.listen((animals) {
      final newStats = _groupByTimeframe(animals);

      // Only detect changes if this is not the initial load and we have previous stats
      List<Map<String, dynamic>> changes = [];
      if (!_isInitialLoad && state.isNotEmpty) {
        changes = _detectChanges(state, newStats);
      }

      // Set initial load to false after first load
      _isInitialLoad = false;

      state = {...newStats, "recentChanges": changes};

      ref.read(recentChangesProvider.notifier).state = changes
          .map((change) => _getActivityMessage(change))
          .toList();
    });
  }

  /// Fetches last email sync time separately
  void _fetchLastEmailSyncTime(String shelterID) {
    _emailSyncSubscription?.cancel();
    final emailSyncStream = _repository.fetchLastEmailSync(shelterID);

    _emailSyncSubscription = emailSyncStream.listen((emailSyncTime) {
      state = {...state, "lastEmailSyncTime": emailSyncTime};

      ref.read(lastEmailSyncProvider.notifier).state = emailSyncTime;
    });
  }

  /// Fetches last API sync data from shelter document
  void _fetchLastSyncData(String shelterID) {
    _syncDataSubscription?.cancel();
    final syncDataStream = _repository.fetchLastSyncData(shelterID);

    _syncDataSubscription = syncDataStream.listen((syncData) {
      // Look for lastApiSync field that's set by the ShelterLuv cloud function
      DateTime? lastApiSync;
      if (syncData.containsKey('lastApiSync')) {
        final lastApiSyncField = syncData['lastApiSync'];
        if (lastApiSyncField is Timestamp) {
          lastApiSync = lastApiSyncField.toDate();
        } else if (lastApiSyncField is String) {
          lastApiSync = DateTime.tryParse(lastApiSyncField);
        }
      }

      // Only update if we have a valid sync time
      if (lastApiSync != null) {
        ref.read(lastSyncProvider.notifier).state = lastApiSync;
      } else {
        // Set to null if no API sync data is available
        ref.read(lastSyncProvider.notifier).state = null;
      }
    });
  }

  Map<String, Map<String, Map<String, int>>> _groupByTimeframe(
    List<Animal> animals,
  ) {
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
        final duration = now
            .difference(animal.logs.last.startTime.toDate())
            .inHours;
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

        final species = animal.species;
        speciesData[interval]?[species] =
            (speciesData[interval]?[species] ?? 0) + 1;

        final colorString = animal.symbolColor.toLowerCase();
        if (colorString.isNotEmpty) {
          colorData[interval]?[colorString] =
              (colorData[interval]?[colorString] ?? 0) + 1;
        }
      }
    }

    return {'Species': speciesData, 'Color': colorData};
  }

  List<Map<String, dynamic>> _detectChanges(
    Map<String, dynamic> oldStats,
    Map<String, Map<String, Map<String, int>>> newStats,
  ) {
    final changes = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (var category in newStats.keys) {
      if (category != 'Species') continue;

      for (var timeframe in newStats[category]!.keys) {
        for (var key in newStats[category]![timeframe]!.keys) {
          final oldValue = oldStats[category]?[timeframe]?[key] ?? 0;
          final newValue = newStats[category]![timeframe]![key]!;
          final difference = newValue - oldValue;

          if (difference > 0) {
            changes.add({
              'type': 'added',
              'species': key,
              'count': difference,
              'timeframe': timeframe,
              'timestamp': now,
            });
          } else if (difference < 0) {
            changes.add({
              'type': 'removed',
              'species': key,
              'count': difference.abs(),
              'timeframe': timeframe,
              'timestamp': now,
            });
          }
        }
      }
    }
    changes.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    return changes.length > 5 ? changes.sublist(0, 5) : changes;
  }

  String _getActivityMessage(Map<String, dynamic> activity) {
    final count = activity['count'];
    final species = activity['species'];
    final timeAgo = _formatTimeAgo(activity['timestamp']);

    return activity['type'] == 'added'
        ? '$count ${_pluralize(species, count)} added ($timeAgo)'
        : '$count ${_pluralize(species, count)} removed ($timeAgo)';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'yesterday';
    return '${difference.inDays}d ago';
  }

  String _pluralize(String word, int count) {
    return count == 1 ? word : '${word}s';
  }

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    _emailSyncSubscription?.cancel();
    _syncDataSubscription?.cancel();
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
final lastEmailSyncProvider = StateProvider<String?>(
  (ref) => "No email sync data available",
);
