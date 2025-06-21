import 'package:shelter_partner/models/api_key.dart';
import 'package:shelter_partner/models/scheduled_report.dart';

class ShelterSettings {
  final List<ScheduledReport> scheduledReports;
  final List<String> catTags;
  final List<String> dogTags;
  final List<String> earlyPutBackReasons;
  final List<String> letOutTypes;
  final List<APIKey> apiKeys;
  final String apiKey;
  final int requestCount;
  final int requestLimit;
  final bool automaticallyPutBackAnimals;
  final bool ignoreVisitWhenAutomaticallyPutBack;
  final int automaticPutBackHours;
  final String shortUUID;
  final int tokenCount;
  final int tokenLimit;
  final DateTime? lastTokenReset;
  final bool showSpecies;
  final bool showBreed;
  final bool showDescription;
  final bool showLocation;
  final bool showMedicalInfo;
  final bool showBehaviorInfo;
  final bool onlyIncludePrimaryPhotoFromShelterLuv;

  ShelterSettings({
    required this.scheduledReports,
    required this.catTags,
    required this.dogTags,
    required this.earlyPutBackReasons,
    required this.letOutTypes,
    required this.apiKeys,
    required this.apiKey,
    required this.requestCount,
    required this.requestLimit,
    this.automaticallyPutBackAnimals = false,
    this.ignoreVisitWhenAutomaticallyPutBack = false,
    this.automaticPutBackHours = 12,
    required this.shortUUID,
    this.tokenCount = 0,
    this.tokenLimit = 1000000,
    this.lastTokenReset,
    this.showSpecies = true,
    this.showBreed = true,
    this.showDescription = true,
    this.showLocation = true,
    this.showMedicalInfo = false,
    this.showBehaviorInfo = true,
    this.onlyIncludePrimaryPhotoFromShelterLuv = true,
  });

  // Method to dynamically return a list based on the key
  List<String> getArray(String key) {
    switch (key) {
      case 'scheduledReports':
        return scheduledReports.map((report) => report.title).toList();
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
      'scheduledReports': scheduledReports
          .map((report) => report.toMap())
          .toList(), // Convert each ScheduledReport to a Map
      'catTags': catTags,
      'dogTags': dogTags,
      'earlyPutBackReasons': earlyPutBackReasons,
      'letOutTypes': letOutTypes,
      'apiKeys': apiKeys
          .map((apiKey) => apiKey.toMap())
          .toList(), // Convert each APIKey to a Map
      'apiKey': apiKey,
      'requestCount': requestCount,
      'requestLimit': requestLimit,
      'automaticallyPutBackAnimals': automaticallyPutBackAnimals,
      'ignoreVisitWhenAutomaticallyPutBack':
          ignoreVisitWhenAutomaticallyPutBack,
      'automaticPutBackHours': automaticPutBackHours,
      'shortUUID': shortUUID,
      'tokenCount': tokenCount,
      'tokenLimit': tokenLimit,
      'lastTokenReset': lastTokenReset?.toIso8601String(),
      'showSpecies': showSpecies,
      'showBreed': showBreed,
      'showDescription': showDescription,
      'showLocation': showLocation,
      'showMedicalInfo': showMedicalInfo,
      'showBehaviorInfo': showBehaviorInfo,
      'onlyIncludePrimaryPhotoFromShelterLuv':
          onlyIncludePrimaryPhotoFromShelterLuv,
    };
  }

  // Factory constructor to create ShelterSettings from Firestore Map
  factory ShelterSettings.fromMap(Map<String, dynamic> data) {
    return ShelterSettings(
      scheduledReports:
          (data['scheduledReports'] as List<dynamic>?)
              ?.map(
                (reportMap) => reportMap is Map<String, dynamic>
                    ? ScheduledReport.fromMap(reportMap)
                    : throw Exception("Invalid ScheduledReport data"),
              )
              .toList() ??
          [],
      catTags:
          (data['catTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dogTags:
          (data['dogTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      earlyPutBackReasons:
          (data['earlyPutBackReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      letOutTypes:
          (data['letOutTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      apiKeys:
          (data['apiKeys'] as List<dynamic>?)
              ?.map(
                (apiKeyMap) => apiKeyMap is Map<String, dynamic>
                    ? APIKey.fromMap(apiKeyMap)
                    : throw Exception("Invalid APIKey data"),
              )
              .toList() ??
          [],
      apiKey: data['apiKey'] ?? '',
      requestCount: data['requestCount'] ?? 0,
      requestLimit: data['requestLimit'] ?? 0,
      automaticallyPutBackAnimals: data['automaticallyPutBackAnimals'] ?? false,
      ignoreVisitWhenAutomaticallyPutBack:
          data['ignoreVisitWhenAutomaticallyPutBack'] ?? false,
      automaticPutBackHours: data['automaticPutBackHours'] ?? 12,
      shortUUID: data['shortUUID'] ?? '',
      tokenCount: data['tokenCount'] ?? 0,
      tokenLimit: data['tokenLimit'] ?? 1000000,
      lastTokenReset: data['lastTokenReset'] != null
          ? DateTime.parse(data['lastTokenReset'])
          : null,
      showSpecies: data['showSpecies'] ?? true,
      showBreed: data['showBreed'] ?? true,
      showDescription: data['showDescription'] ?? true,
      showLocation: data['showLocation'] ?? true,
      showMedicalInfo: data['showMedicalInfo'] ?? false,
      showBehaviorInfo: data['showBehaviorInfo'] ?? true,
      onlyIncludePrimaryPhotoFromShelterLuv:
          data['onlyIncludePrimaryPhotoFromShelterLuv'] ?? true,
    );
  }

  ShelterSettings copyWith({
    List<ScheduledReport>? scheduledReports,
    List<String>? catTags,
    List<String>? dogTags,
    List<String>? earlyPutBackReasons,
    List<String>? letOutTypes,
    List<APIKey>? apiKeys,
    String? apiKey,
    int? requestCount,
    int? requestLimit,
    bool? automaticallyPutBackAnimals,
    bool? ignoreVisitWhenAutomaticallyPutBack,
    int? automaticPutBackHours,
    String? shortUUID,
    bool? showSpecies,
    bool? showBreed,
    bool? showDescription,
    bool? showLocation,
    bool? showMedicalInfo,
    bool? showBehaviorInfo,
    bool? onlyIncludePrimaryPhotoFromShelterLuv,
    int? tokenCount,
    int? tokenLimit,
    DateTime? lastTokenReset,
  }) {
    return ShelterSettings(
      scheduledReports: scheduledReports ?? this.scheduledReports,
      catTags: catTags ?? this.catTags,
      dogTags: dogTags ?? this.dogTags,
      earlyPutBackReasons: earlyPutBackReasons ?? this.earlyPutBackReasons,
      letOutTypes: letOutTypes ?? this.letOutTypes,
      apiKeys: apiKeys ?? this.apiKeys,
      apiKey: apiKey ?? this.apiKey,
      requestCount: requestCount ?? this.requestCount,
      requestLimit: requestLimit ?? this.requestLimit,
      automaticallyPutBackAnimals:
          automaticallyPutBackAnimals ?? this.automaticallyPutBackAnimals,
      ignoreVisitWhenAutomaticallyPutBack:
          ignoreVisitWhenAutomaticallyPutBack ??
          this.ignoreVisitWhenAutomaticallyPutBack,
      automaticPutBackHours:
          automaticPutBackHours ?? this.automaticPutBackHours,
      shortUUID: shortUUID ?? this.shortUUID,
      showSpecies: showSpecies ?? this.showSpecies,
      showBreed: showBreed ?? this.showBreed,
      showDescription: showDescription ?? this.showDescription,
      showLocation: showLocation ?? this.showLocation,
      showMedicalInfo: showMedicalInfo ?? this.showMedicalInfo,
      showBehaviorInfo: showBehaviorInfo ?? this.showBehaviorInfo,
      onlyIncludePrimaryPhotoFromShelterLuv:
          onlyIncludePrimaryPhotoFromShelterLuv ??
          this.onlyIncludePrimaryPhotoFromShelterLuv,
      tokenCount: tokenCount ?? this.tokenCount,
      tokenLimit: tokenLimit ?? this.tokenLimit,
      lastTokenReset: lastTokenReset ?? this.lastTokenReset,
    );
  }
}
