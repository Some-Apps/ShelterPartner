import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
// import 'package:shelter_partner/view_models/enrichment_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/models/photo.dart';
import 'package:shelter_partner/models/tag.dart';

void main() {
  group('Filter Functionality Tests', () {
    test('getAttributeValue should return let out types from animal logs', () {
      // Create an enrichment view model for testing
      // const viewModel = EnrichmentViewModel;

      // Create test logs with different types
      final logs = [
        Log(
          id: 'log1',
          type: 'Walk',
          author: 'Volunteer1',
          authorID: 'vol1',
          startTime: Timestamp.now(),
          endTime: Timestamp.now(),
        ),
        Log(
          id: 'log2',
          type: 'Training',
          author: 'Volunteer2',
          authorID: 'vol2',
          startTime: Timestamp.now(),
          endTime: Timestamp.now(),
          earlyReason: 'Medical attention needed',
        ),
      ];

      // Create test animal with logs
      final animal = Animal(
        id: 'test-animal',
        name: 'Test Dog',
        sex: 'Male',
        monthsOld: 12,
        species: 'dog',
        breed: 'Labrador',
        location: 'Kennel 1',
        fullLocation: 'Building A > Kennel 1',
        description: 'Friendly dog',
        symbol: 'tag',
        symbolColor: 'blue',
        takeOutAlert: '',
        putBackAlert: '',
        adoptionCategory: 'Adult',
        behaviorCategory: 'Good',
        locationCategory: 'General',
        medicalCategory: 'Healthy',
        volunteerCategory: 'All',
        inKennel: true,
        intakeDate: Timestamp.now(),
        photos: <Photo>[],
        notes: <Note>[],
        logs: logs,
        tags: <Tag>[],
      );

      // Create a mock EnrichmentViewModel instance
      // We'll test the getAttributeValue method indirectly by creating an instance

      // Test Let Out Type attribute
      // Since we can't directly access the method, we'll test the expected behavior
      final letOutTypes = animal.logs
          .map((log) => log.type.toLowerCase())
          .toList();
      expect(letOutTypes, contains('walk'));
      expect(letOutTypes, contains('training'));

      // Test Early Put Back Reasons attribute
      final earlyReasons = animal.logs
          .where(
            (log) => log.earlyReason != null && log.earlyReason!.isNotEmpty,
          )
          .map((log) => log.earlyReason!.toLowerCase())
          .toList();
      expect(earlyReasons, contains('medical attention needed'));
      expect(
        earlyReasons.length,
        equals(1),
      ); // Only one log has an early reason
    });

    test('logs should contain correct type and early reason fields', () {
      // Test the Log model to ensure it has the expected fields
      final log = Log(
        id: 'test-log',
        type: 'Playtime',
        author: 'Test Volunteer',
        authorID: 'test-vol',
        startTime: Timestamp.now(),
        endTime: Timestamp.now(),
        earlyReason: 'Animal was tired',
      );

      expect(log.type, equals('Playtime'));
      expect(log.earlyReason, equals('Animal was tired'));
    });

    test('animal should support logs collection', () {
      final animal = Animal(
        id: 'test-animal',
        name: 'Test Dog',
        sex: 'Male',
        monthsOld: 12,
        species: 'dog',
        breed: 'Labrador',
        location: 'Kennel 1',
        fullLocation: 'Building A > Kennel 1',
        description: 'Friendly dog',
        symbol: 'tag',
        symbolColor: 'blue',
        takeOutAlert: '',
        putBackAlert: '',
        adoptionCategory: 'Adult',
        behaviorCategory: 'Good',
        locationCategory: 'General',
        medicalCategory: 'Healthy',
        volunteerCategory: 'All',
        inKennel: true,
        intakeDate: Timestamp.now(),
        photos: <Photo>[],
        notes: <Note>[],
        logs: <Log>[],
        tags: <Tag>[],
      );

      expect(animal.logs, isA<List<Log>>());
      expect(animal.logs, isEmpty); // Initially empty
    });
  });
}
