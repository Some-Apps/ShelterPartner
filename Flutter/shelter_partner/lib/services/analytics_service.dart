import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Abstract interface for analytics tracking
abstract class AnalyticsService {
  /// Initialize analytics and set user properties
  Future<void> initialize();

  /// Track when a note is added to an animal
  Future<void> trackNoteAdded(String animalId, String animalSpecies);

  /// Track when a photo is added to an animal
  Future<void> trackPhotoAdded(
    String animalId,
    String animalSpecies,
    String source,
  );

  /// Track when a tag is added to an animal
  Future<void> trackTagAdded(
    String animalId,
    String animalSpecies,
    String tagName,
  );

  /// Track when a log is completed (animal put back)
  Future<void> trackLogCompleted(
    String animalId,
    String animalSpecies,
    String logType,
  );

  /// Set user ID for analytics (when user logs in)
  Future<void> setUserId(String userId);

  /// Set user properties
  Future<void> setUserProperty(String name, String value);
}

/// Firebase Analytics implementation
class FirebaseAnalyticsService implements AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  static FirebaseAnalytics get analytics {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  static FirebaseAnalyticsObserver get observer {
    _observer ??= FirebaseAnalyticsObserver(analytics: analytics);
    return _observer!;
  }

  @override
  Future<void> initialize() async {
    try {
      // Set app version as user property
      final packageInfo = await PackageInfo.fromPlatform();
      await setUserProperty('app_version', packageInfo.version);

      // Enable analytics collection
      await analytics.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      // Silently fail - analytics should not break the app
    }
  }

  @override
  Future<void> trackNoteAdded(String animalId, String animalSpecies) async {
    try {
      await analytics.logEvent(
        name: 'note_added',
        parameters: {
          'animal_id': animalId,
          'animal_species': animalSpecies.toLowerCase(),
        },
      );
    } catch (e) {
      // Silently fail - analytics should not break the app
    }
  }

  @override
  Future<void> trackPhotoAdded(
    String animalId,
    String animalSpecies,
    String source,
  ) async {
    try {
      await analytics.logEvent(
        name: 'photo_added',
        parameters: {
          'animal_id': animalId,
          'animal_species': animalSpecies.toLowerCase(),
          'photo_source': source,
        },
      );
    } catch (e) {
      // Silently fail - analytics should not break the app
    }
  }

  @override
  Future<void> trackTagAdded(
    String animalId,
    String animalSpecies,
    String tagName,
  ) async {
    try {
      await analytics.logEvent(
        name: 'tag_added',
        parameters: {
          'animal_id': animalId,
          'animal_species': animalSpecies.toLowerCase(),
          'tag_name': tagName,
        },
      );
    } catch (e) {
      // Silently fail - analytics should not break the app
    }
  }

  @override
  Future<void> trackLogCompleted(
    String animalId,
    String animalSpecies,
    String logType,
  ) async {
    try {
      await analytics.logEvent(
        name: 'log_completed',
        parameters: {
          'animal_id': animalId,
          'animal_species': animalSpecies.toLowerCase(),
          'log_type': logType,
        },
      );
    } catch (e) {
      // Silently fail - analytics should not break the app
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      await analytics.setUserId(id: userId);
    } catch (e) {
      // Silently fail - analytics should not break the app
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    try {
      await analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      // Silently fail - analytics should not break the app
    }
  }
}

/// Mock analytics service for testing
class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> _events = [];
  final Map<String, String> _userProperties = {};
  String? _userId;

  /// Get all tracked events (for testing)
  List<Map<String, dynamic>> get events => List.unmodifiable(_events);

  /// Get user properties (for testing)
  Map<String, String> get userProperties => Map.unmodifiable(_userProperties);

  /// Get user ID (for testing)
  String? get userId => _userId;

  /// Clear all tracked data (for testing)
  void clear() {
    _events.clear();
    _userProperties.clear();
    _userId = null;
  }

  @override
  Future<void> initialize() async {
    // Mock initialization - do nothing
  }

  @override
  Future<void> trackNoteAdded(String animalId, String animalSpecies) async {
    _events.add({
      'event': 'note_added',
      'animal_id': animalId,
      'animal_species': animalSpecies.toLowerCase(),
    });
  }

  @override
  Future<void> trackPhotoAdded(
    String animalId,
    String animalSpecies,
    String source,
  ) async {
    _events.add({
      'event': 'photo_added',
      'animal_id': animalId,
      'animal_species': animalSpecies.toLowerCase(),
      'photo_source': source,
    });
  }

  @override
  Future<void> trackTagAdded(
    String animalId,
    String animalSpecies,
    String tagName,
  ) async {
    _events.add({
      'event': 'tag_added',
      'animal_id': animalId,
      'animal_species': animalSpecies.toLowerCase(),
      'tag_name': tagName,
    });
  }

  @override
  Future<void> trackLogCompleted(
    String animalId,
    String animalSpecies,
    String logType,
  ) async {
    _events.add({
      'event': 'log_completed',
      'animal_id': animalId,
      'animal_species': animalSpecies.toLowerCase(),
      'log_type': logType,
    });
  }

  @override
  Future<void> setUserId(String userId) async {
    _userId = userId;
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    _userProperties[name] = value;
  }
}

/// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});
