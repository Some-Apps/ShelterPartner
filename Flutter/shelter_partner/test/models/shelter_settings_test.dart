import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/models/shelter_settings.dart';

void main() {
  group('ShelterSettings', () {
    test('should have default value for onlyIncludePrimaryPhotoFromShelterLuv', () {
      final shelterSettings = ShelterSettings(
        scheduledReports: [],
        catTags: [],
        dogTags: [],
        earlyPutBackReasons: [],
        letOutTypes: [],
        apiKeys: [],
        apiKey: '',
        asmUsername: '',
        asmPassword: '',
        asmAccountNumber: '',
        requestCount: 0,
        requestLimit: 0,
        shortUUID: '',
      );

      expect(shelterSettings.onlyIncludePrimaryPhotoFromShelterLuv, isTrue);
    });

    test('should serialize and deserialize onlyIncludePrimaryPhotoFromShelterLuv correctly', () {
      final originalSettings = ShelterSettings(
        scheduledReports: [],
        catTags: [],
        dogTags: [],
        earlyPutBackReasons: [],
        letOutTypes: [],
        apiKeys: [],
        apiKey: '',
        asmUsername: '',
        asmPassword: '',
        asmAccountNumber: '',
        requestCount: 0,
        requestLimit: 0,
        shortUUID: '',
        onlyIncludePrimaryPhotoFromShelterLuv: false,
      );

      final map = originalSettings.toMap();
      final deserializedSettings = ShelterSettings.fromMap(map);

      expect(deserializedSettings.onlyIncludePrimaryPhotoFromShelterLuv, isFalse);
    });

    test('should use default value when field is missing from map', () {
      final map = <String, dynamic>{
        'scheduledReports': <dynamic>[],
        'catTags': <dynamic>[],
        'dogTags': <dynamic>[],
        'earlyPutBackReasons': <dynamic>[],
        'letOutTypes': <dynamic>[],
        'apiKeys': <dynamic>[],
        'apiKey': '',
        'asmUsername': '',
        'asmPassword': '',
        'asmAccountNumber': '',
        'requestCount': 0,
        'requestLimit': 0,
        'shortUUID': '',
        // Missing onlyIncludePrimaryPhotoFromShelterLuv field
      };

      final settings = ShelterSettings.fromMap(map);
      expect(settings.onlyIncludePrimaryPhotoFromShelterLuv, isTrue);
    });

    test('copyWith should preserve onlyIncludePrimaryPhotoFromShelterLuv value', () {
      final originalSettings = ShelterSettings(
        scheduledReports: [],
        catTags: [],
        dogTags: [],
        earlyPutBackReasons: [],
        letOutTypes: [],
        apiKeys: [],
        apiKey: '',
        asmUsername: '',
        asmPassword: '',
        asmAccountNumber: '',
        requestCount: 0,
        requestLimit: 0,
        shortUUID: '',
        onlyIncludePrimaryPhotoFromShelterLuv: false,
      );

      final copiedSettings = originalSettings.copyWith(
        onlyIncludePrimaryPhotoFromShelterLuv: true,
      );

      expect(copiedSettings.onlyIncludePrimaryPhotoFromShelterLuv, isTrue);
      expect(originalSettings.onlyIncludePrimaryPhotoFromShelterLuv, isFalse);
    });
  });
}