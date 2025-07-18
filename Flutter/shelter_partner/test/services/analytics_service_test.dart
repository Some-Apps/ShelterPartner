import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      mockAnalytics = MockAnalyticsService();
    });

    tearDown(() {
      mockAnalytics.clear();
    });

    test('should implement AnalyticsService interface', () {
      expect(mockAnalytics, isA<AnalyticsService>());
    });

    test('should track note added events', () async {
      const animalId = 'test-animal-123';
      const animalSpecies = 'Cat';

      await mockAnalytics.trackNoteAdded(animalId, animalSpecies);

      expect(mockAnalytics.events, hasLength(1));
      expect(mockAnalytics.events.first, {
        'event': 'note_added',
        'animal_id': animalId,
        'animal_species': 'cat',
      });
    });

    test('should track photo added events', () async {
      const animalId = 'test-animal-456';
      const animalSpecies = 'Dog';
      const source = 'manual';

      await mockAnalytics.trackPhotoAdded(animalId, animalSpecies, source);

      expect(mockAnalytics.events, hasLength(1));
      expect(mockAnalytics.events.first, {
        'event': 'photo_added',
        'animal_id': animalId,
        'animal_species': 'dog',
        'photo_source': source,
      });
    });

    test('should track tag added events', () async {
      const animalId = 'test-animal-789';
      const animalSpecies = 'Cat';
      const tagName = 'friendly';

      await mockAnalytics.trackTagAdded(animalId, animalSpecies, tagName);

      expect(mockAnalytics.events, hasLength(1));
      expect(mockAnalytics.events.first, {
        'event': 'tag_added',
        'animal_id': animalId,
        'animal_species': 'cat',
        'tag_name': tagName,
      });
    });

    test('should track log completed events', () async {
      const animalId = 'test-animal-101';
      const animalSpecies = 'Dog';
      const logType = 'walk';

      await mockAnalytics.trackLogCompleted(animalId, animalSpecies, logType);

      expect(mockAnalytics.events, hasLength(1));
      expect(mockAnalytics.events.first, {
        'event': 'log_completed',
        'animal_id': animalId,
        'animal_species': 'dog',
        'log_type': logType,
      });
    });

    test('should set user ID', () async {
      const userId = 'test-user-123';

      await mockAnalytics.setUserId(userId);

      expect(mockAnalytics.userId, equals(userId));
    });

    test('should set user properties', () async {
      const propertyName = 'app_version';
      const propertyValue = '2.0.3';

      await mockAnalytics.setUserProperty(propertyName, propertyValue);

      expect(mockAnalytics.userProperties[propertyName], equals(propertyValue));
    });

    test('should handle multiple events', () async {
      await mockAnalytics.trackNoteAdded('animal1', 'cat');
      await mockAnalytics.trackPhotoAdded('animal2', 'dog', 'manual');
      await mockAnalytics.trackTagAdded('animal3', 'cat', 'playful');

      expect(mockAnalytics.events, hasLength(3));
      expect(mockAnalytics.events[0]['event'], equals('note_added'));
      expect(mockAnalytics.events[1]['event'], equals('photo_added'));
      expect(mockAnalytics.events[2]['event'], equals('tag_added'));
    });

    test('should clear all data when requested', () async {
      await mockAnalytics.trackNoteAdded('animal1', 'cat');
      await mockAnalytics.setUserId('user123');
      await mockAnalytics.setUserProperty('test', 'value');

      expect(mockAnalytics.events, hasLength(1));
      expect(mockAnalytics.userId, isNotNull);
      expect(mockAnalytics.userProperties, isNotEmpty);

      mockAnalytics.clear();

      expect(mockAnalytics.events, isEmpty);
      expect(mockAnalytics.userId, isNull);
      expect(mockAnalytics.userProperties, isEmpty);
    });

    test('should normalize animal species to lowercase', () async {
      await mockAnalytics.trackNoteAdded('animal1', 'CAT');
      await mockAnalytics.trackPhotoAdded('animal2', 'DOG', 'auto');

      expect(mockAnalytics.events[0]['animal_species'], equals('cat'));
      expect(mockAnalytics.events[1]['animal_species'], equals('dog'));
    });
  });
}
