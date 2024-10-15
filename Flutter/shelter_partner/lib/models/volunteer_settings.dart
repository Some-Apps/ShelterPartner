import 'package:shelter_partner/models/geofence.dart';

class VolunteerSettings {
  final bool photoUploadsAllowed;
  final String mainSort;
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
  final bool showCustomForm;
  final String customFormURL;
  final bool appendAnimalDataToURL;
  final Geofence? geofence; // Optional geofence field

  VolunteerSettings({
    required this.photoUploadsAllowed,
    required this.mainSort,
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
    required this.showCustomForm,
    required this.customFormURL,
    required this.appendAnimalDataToURL,
    this.geofence, // Can be null
  });

  // Convert VolunteerSettings to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'photoUploadsAllowed': photoUploadsAllowed,
      'mainSort': mainSort,
      'allowBulkTakeOut': allowBulkTakeOut,
      'minimumLogMinutes': minimumLogMinutes,
      'automaticallyPutBackAnimals': automaticallyPutBackAnimals,
      'ignoreVisitWhenAutomaticallyPutBack':
          ignoreVisitWhenAutomaticallyPutBack,
      'automaticPutBackHours': automaticPutBackHours,
      'requireLetOutType': requireLetOutType,
      'requireEarlyPutBackReason': requireEarlyPutBackReason,
      'requireName': requireName,
      'createLogsWhenUnderMinimumDuration': createLogsWhenUnderMinimumDuration,
      'showNoteDates': showNoteDates,
      'showLogs': showLogs,
      'showAllAnimals': showAllAnimals,
      'showCustomForm': showCustomForm,
      'customFormURL': customFormURL,
      'appendAnimalDataToURL': appendAnimalDataToURL,
      'geofence': geofence?.toMap(), // Only include if not null
    };
  }

  // Factory constructor to create VolunteerSettings from Firestore Map
  factory VolunteerSettings.fromMap(Map<String, dynamic> data) {
    return VolunteerSettings(
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      mainSort: data['mainSort'] ?? "None",
      allowBulkTakeOut: data['allowBulkTakeOut'] ?? false,
      minimumLogMinutes: data['minimumLogMinutes'] ?? 0,
      automaticallyPutBackAnimals: data['automaticallyPutBackAnimals'] ?? false,
      ignoreVisitWhenAutomaticallyPutBack:
          data['ignoreVisitWhenAutomaticallyPutBack'] ?? false,
      automaticPutBackHours: data['automaticPutBackHours'] ?? 0,
      requireLetOutType: data['requireLetOutType'] ?? false,
      requireEarlyPutBackReason: data['requireEarlyPutBackReason'] ?? false,
      requireName: data['requireName'] ?? false,
      createLogsWhenUnderMinimumDuration:
          data['createLogsWhenUnderMinimumDuration'] ?? false,
      showNoteDates: data['showNoteDates'] ?? false,
      showLogs: data['showLogs'] ?? false,
      showAllAnimals: data['showAllAnimals'] ?? false,
      showCustomForm: data['showCustomForm'] ?? false,
      customFormURL: data['customFormURL'] ?? "",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
      geofence: data['geofence'] != null
          ? Geofence.fromMap(data['geofence'] as Map<String, dynamic>)
          : null, // Handle null geofence safely
    );
  }
}
