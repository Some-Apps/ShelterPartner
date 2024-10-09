import 'package:shelter_partner/models/api_key.dart';

class ShelterSettings {
  final List<String> catTags;
  final List<String> dogTags;
  final List<String> earlyPutBackReasons;
  final List<String> letOutTypes;
  final List<APIKey> apiKeys;

  ShelterSettings({
    required this.catTags,
    required this.dogTags,
    required this.earlyPutBackReasons,
    required this.letOutTypes,
    required this.apiKeys,
  });

    // Method to dynamically return a list based on the key
  List<String> getArray(String key) {
    switch (key) {
      case 'catTags':
        return catTags;
      case 'dogTags':
        return dogTags;
      case 'earlyPutBackReasons':
        return earlyPutBackReasons;
      case 'letOutTypes':
        return letOutTypes;
      default:
        throw Exception('Invalid array key');
    }
  }

  // Convert ShelterSettings to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'catTags': catTags,
      'dogTags': dogTags,
      'earlyPutBackReasons': earlyPutBackReasons,
      'letOutTypes': letOutTypes,
      'apiKeys': apiKeys
          .map((apiKey) => apiKey.toMap())
          .toList(), // Convert each APIKey to a Map
    };
  }

  // Factory constructor to create ShelterSettings from Firestore Map
  factory ShelterSettings.fromMap(Map<String, dynamic> data) {
    return ShelterSettings(
      catTags: (data['catTags'] as List<dynamic>)
              .map((e) => e.toString())
              .toList() ??
          [],
      dogTags: (data['dogTags'] as List<dynamic>)
              .map((e) => e.toString())
              .toList() ??
          [],
      earlyPutBackReasons: (data['earlyPutBackReasons'] as List<dynamic>)
              .map((e) => e.toString())
              .toList() ??
          [],
      letOutTypes: (data['letOutTypes'] as List<dynamic>)
              .map((e) => e.toString())
              .toList() ??
          [],
      apiKeys: (data['apiKeys'] as List<dynamic>)
          .map((apiKeyMap) => APIKey.fromMap(apiKeyMap as Map<String, dynamic>))
          .toList(),
    );
  }
}