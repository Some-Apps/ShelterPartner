import 'package:cloud_firestore/cloud_firestore.dart';

class Shelter {
  final String id;
  final String name;
  final String address;
  final Timestamp createdAt;
  final String managementSoftware;

  final ShelterSettings shelterSettings;
  final DeviceSettings deviceSettings;
  final VolunteerSettings volunteerSettings;

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    required this.managementSoftware,
    required this.shelterSettings,
    required this.deviceSettings,
    required this.volunteerSettings,
  });

  // Factory constructor to parse the document from Firestore
  factory Shelter.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safely handle the `createdAt` field to ensure it's a valid `Timestamp`.
    return Shelter(
      id: doc.id,
      name: data['name'] ?? 'Unknown Shelter', // Default value for name
      address: data['address'] ?? 'Unknown Address', // Default value for address
      createdAt: data['createdAt'] != null
          ? data['createdAt'] as Timestamp
          : Timestamp.now(), // Default value if createdAt is null
      managementSoftware: data['management_software'] ?? 'Unknown Software', // Default value for management software
      shelterSettings: ShelterSettings.fromMap(data['shelterSettings'] ?? {}),
      deviceSettings: DeviceSettings.fromMap(data['deviceSettings'] ?? {}),
      volunteerSettings: VolunteerSettings.fromMap(data['volunteerSettings'] ?? {}),
    );
  }
}


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

class DeviceSettings {
  final List<ScheduledReport> scheduledReports;
  final bool adminMode;
  final bool photoUploadsAllowed;
  final String mainSort;
  final String secondarySort;
  final String groupBy;
  final bool allowBulkTakeOut;
  final int minimumLogMinutes;
  final bool automaticallyPutBackAnimals;
  final bool ignoreVisitWhenAutomaticallyPutBack;
  final int automaticPutBackHours;
  final bool requireLetOutType;
  final bool requireEarlyPutBackReason;
  final bool requireName;
  final bool createLogsWhenUnderMinimumDuration;
  final bool showNoteDates;
  final bool showLogs;
  final bool showAllAnimals;
  final bool showSearchBar;
  final bool showFilter;
  final bool showCustomForm;
  final Uri customFormURL;
  final String buttonType;
  final bool appendAnimalDataToURL;

  DeviceSettings({
    required this.scheduledReports,
    required this.adminMode,
    required this.photoUploadsAllowed,
    required this.mainSort,
    required this.secondarySort,
    required this.groupBy,
    required this.allowBulkTakeOut,
    required this.minimumLogMinutes,
    required this.automaticallyPutBackAnimals,
    required this.ignoreVisitWhenAutomaticallyPutBack,
    required this.automaticPutBackHours,
    required this.requireLetOutType,
    required this.requireEarlyPutBackReason,
    required this.requireName,
    required this.createLogsWhenUnderMinimumDuration,
    required this.showNoteDates,
    required this.showLogs,
    required this.showAllAnimals,
    required this.showSearchBar,
    required this.showFilter,
    required this.showCustomForm,
    required this.customFormURL,
    required this.buttonType,
    required this.appendAnimalDataToURL,
  });

  // Convert DeviceSettings to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'scheduledReports': scheduledReports.map((report) => report.toMap()).toList(),
      'adminMode': adminMode,
      'photoUploadsAllowed': photoUploadsAllowed,
      'mainSort': mainSort,
      'secondarySort': secondarySort,
      'groupBy': groupBy,
      'allowBulkTakeOut': allowBulkTakeOut,
      'minimumLogMinutes': minimumLogMinutes,
      'automaticallyPutBackAnimals': automaticallyPutBackAnimals,
      'ignoreVisitWhenAutomaticallyPutBack': ignoreVisitWhenAutomaticallyPutBack,
      'automaticPutBackHours': automaticPutBackHours,
      'requireLetOutType': requireLetOutType,
      'requireEarlyPutBackReason': requireEarlyPutBackReason,
      'requireName': requireName,
      'createLogsWhenUnderMinimumDuration': createLogsWhenUnderMinimumDuration,
      'showNoteDates': showNoteDates,
      'showLogs': showLogs,
      'showAllAnimals': showAllAnimals,
      'showSearchBar': showSearchBar,
      'showFilter': showFilter,
      'showCustomForm': showCustomForm,
      'customFormURL': customFormURL.toString(), // Convert Uri to String here
      'buttonType': buttonType,
      'appendAnimalDataToURL': appendAnimalDataToURL,
    };
  }

  // Factory constructor to create DeviceSettings from Firestore Map
  factory DeviceSettings.fromMap(Map<String, dynamic> data) {
    return DeviceSettings(
      scheduledReports: (data['scheduledReports'] as List<dynamic>)
          .map((reportMap) => ScheduledReport.fromMap(reportMap as Map<String, dynamic>))
          .toList(),
      adminMode: data['adminMode'] ?? false,
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      mainSort: data['mainSort'] ?? "Unknown",
      secondarySort: data['secondarySort'] ?? "Unknown",
      groupBy: data['groupBy'] ?? "Unknown",
      allowBulkTakeOut: data['allowBulkTakeOut'] ?? false,
      minimumLogMinutes: data['minimumLogMinutes'] ?? 0,
      automaticallyPutBackAnimals: data['automaticallyPutBackAnimals'] ?? false,
      ignoreVisitWhenAutomaticallyPutBack: data['ignoreVisitWhenAutomaticallyPutBack'] ?? false,
      automaticPutBackHours: data['automaticPutBackHours'] ?? 0,
      requireLetOutType: data['requireLetOutType'] ?? false,
      requireEarlyPutBackReason: data['requireEarlyPutBackReason'] ?? false,
      requireName: data['requireName'] ?? false,
      createLogsWhenUnderMinimumDuration: data['createLogsWhenUnderMinimumDuration'] ?? false,
      showNoteDates: data['showNoteDates'] ?? false,
      showLogs: data['showLogs'] ?? false,
      showAllAnimals: data['showAllAnimals'] ?? false,
      showSearchBar: data['showSearchBar'] ?? false,
      showFilter: data['showFilter'] ?? false,
      showCustomForm: data['showCustomForm'] ?? false,
      customFormURL: Uri.parse(data['customFormURL'] ?? ""), // Convert String back to Uri
      buttonType: data['buttonType'] ?? "Unknown",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
    );
  }
}

class VolunteerSettings {
  final bool photoUploadsAllowed;
  final String mainSort;
  final String secondarySort;
  final String groupBy;
  final bool allowBulkTakeOut;
  final int minimumLogMinutes;
  final bool automaticallyPutBackAnimals;
  final bool ignoreVisitWhenAutomaticallyPutBack;
  final int automaticPutBackHours;
  final bool requireLetOutType;
  final bool requireEarlyPutBackReason;
  final bool requireName;
  final bool createLogsWhenUnderMinimumDuration;
  final bool showNoteDates;
  final bool showLogs;
  final bool showAllAnimals;
  final bool showSearchBar;
  final bool showFilter;
  final bool showCustomForm;
  final Uri customFormURL;
  final String buttonType;
  final bool appendAnimalDataToURL;

  VolunteerSettings({
    required this.photoUploadsAllowed,
    required this.mainSort,
    required this.secondarySort,
    required this.groupBy,
    required this.allowBulkTakeOut,
    required this.minimumLogMinutes,
    required this.automaticallyPutBackAnimals,
    required this.ignoreVisitWhenAutomaticallyPutBack,
    required this.automaticPutBackHours,
    required this.requireLetOutType,
    required this.requireEarlyPutBackReason,
    required this.requireName,
    required this.createLogsWhenUnderMinimumDuration,
    required this.showNoteDates,
    required this.showLogs,
    required this.showAllAnimals,
    required this.showSearchBar,
    required this.showFilter,
    required this.showCustomForm,
    required this.customFormURL,
    required this.buttonType,
    required this.appendAnimalDataToURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'photoUploadsAllowed': photoUploadsAllowed,
      'mainSort': mainSort,
      'secondarySort': secondarySort,
      'groupBy': groupBy,
      'allowBulkTakeOut': allowBulkTakeOut,
      'minimumLogMinutes': minimumLogMinutes,
      'automaticallyPutBackAnimals': automaticallyPutBackAnimals,
      'ignoreVisitWhenAutomaticallyPutBack': ignoreVisitWhenAutomaticallyPutBack,
      'automaticPutBackHours': automaticPutBackHours,
      'requireLetOutType': requireLetOutType,
      'requireEarlyPutBackReason': requireEarlyPutBackReason,
      'requireName': requireName,
      'createLogsWhenUnderMinimumDuration': createLogsWhenUnderMinimumDuration,
      'showNoteDates': showNoteDates,
      'showLogs': showLogs,
      'showAllAnimals': showAllAnimals,
      'showSearchBar': showSearchBar,
      'showFilter': showFilter,
      'showCustomForm': showCustomForm,
      'customFormURL': customFormURL.toString(), // Convert Uri to String here
      'buttonType': buttonType,
      'appendAnimalDataToURL': appendAnimalDataToURL,
    };
  }

  factory VolunteerSettings.fromMap(Map<String, dynamic> data) {
    return VolunteerSettings(
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      mainSort: data['mainSort'] ?? "Unknown",
      secondarySort: data['secondarySort'] ?? "Unknown",
      groupBy: data['groupBy'] ?? "Unknown",
      allowBulkTakeOut: data['allowBulkTakeOut'] ?? false,
      minimumLogMinutes: data['minimumLogMinutes'] ?? 0,
      automaticallyPutBackAnimals: data['automaticallyPutBackAnimals'] ?? false,
      ignoreVisitWhenAutomaticallyPutBack: data['ignoreVisitWhenAutomaticallyPutBack'] ?? false,
      automaticPutBackHours: data['automaticPutBackHours'] ?? 0,
      requireLetOutType: data['requireLetOutType'] ?? false,
      requireEarlyPutBackReason: data['requireEarlyPutBackReason'] ?? false,
      requireName: data['requireName'] ?? false,
      createLogsWhenUnderMinimumDuration: data['createLogsWhenUnderMinimumDuration'] ?? false,
      showNoteDates: data['showNoteDates'] ?? false,
      showLogs: data['showLogs'] ?? false,
      showAllAnimals: data['showAllAnimals'] ?? false,
      showSearchBar: data['showSearchBar'] ?? false,
      showFilter: data['showFilter'] ?? false,
      showCustomForm: data['showCustomForm'] ?? false,
      customFormURL: Uri.parse(data['customFormURL'] ?? ""), // Convert String back to Uri
      buttonType: data['buttonType'] ?? "Unknown",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
    );
  }
}


class ScheduledReport {
  final String email;
  final List<String> days;
  final String type;

  ScheduledReport({
    required this.email,
    required this.days,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'days': days,
      'type': type,
    };
  }

  factory ScheduledReport.fromMap(Map<String, dynamic> data) {
    return ScheduledReport(
      email: data['email'] ?? "Unknown",
      days: List<String>.from(data['days'] ?? []),
      type: data['type'] ?? "Unknown",
    );
  }
}


class APIKey {
  final String name;
  final String key;

  APIKey({
    required this.name,
    required this.key,
  });

  factory APIKey.fromMap(Map<String, dynamic> data) {
    return APIKey(
      name: data['name'] ?? "Unknown",
      key: data['key'] ?? "Unknown",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'key': key,
    };
  }
}
