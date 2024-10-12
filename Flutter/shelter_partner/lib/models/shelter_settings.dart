import 'package:shelter_partner/models/api_key.dart';

class ShelterSettings {
  final List<String> catTags;
  final List<String> dogTags;
  final List<String> earlyPutBackReasons;
  final List<String> letOutTypes;
  final List<APIKey> apiKeys;
  final int requestCount;
  final int requestLimit;

  ShelterSettings({
    required this.catTags,
    required this.dogTags,
    required this.earlyPutBackReasons,
    required this.letOutTypes,
    required this.apiKeys,
    required this.requestCount,
    required this.requestLimit,
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
      case 'apiKeys':
        return apiKeys.map((apiKey) => apiKey.name).toList();
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
      'requestCount': requestCount,
      'requestLimit': requestLimit,
    };
  }

  // Factory constructor to create ShelterSettings from Firestore Map
  factory ShelterSettings.fromMap(Map<String, dynamic> data) {
    return ShelterSettings(
      catTags: (data['catTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dogTags: (data['dogTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      earlyPutBackReasons: (data['earlyPutBackReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      letOutTypes: (data['letOutTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      apiKeys: (data['apiKeys'] as List<dynamic>?)
              ?.map((apiKeyMap) => 
                  apiKeyMap is Map<String, dynamic> ? APIKey.fromMap(apiKeyMap) : throw Exception("Invalid APIKey data"))
              .toList() ?? [],
      requestCount: data['requestCount'] ?? 0,
      requestLimit: data['requestLimit'] ?? 0,
    );
  }
}
