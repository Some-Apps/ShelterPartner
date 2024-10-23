import 'package:shelter_partner/models/geofence.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';

class VolunteerSettings {
  final bool photoUploadsAllowed;
  final String mainSort;
  final FilterElement? mainFilter;
  final bool allowBulkTakeOut;
  final int minimumLogMinutes;
  final bool requireLetOutType;
  final bool requireEarlyPutBackReason;
  final bool requireName;
  final bool createLogsWhenUnderMinimumDuration;
  final bool showCustomForm;
  final String customFormURL;
  final bool appendAnimalDataToURL;
  final Geofence? geofence; // Optional geofence field

  VolunteerSettings({
    required this.photoUploadsAllowed,
    required this.mainSort,
    required this.mainFilter,
    required this.allowBulkTakeOut,
    required this.minimumLogMinutes,
    required this.requireLetOutType,
    required this.requireEarlyPutBackReason,
    required this.requireName,
    required this.createLogsWhenUnderMinimumDuration,
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
      'mainFilter': mainFilter,
      'allowBulkTakeOut': allowBulkTakeOut,
      'minimumLogMinutes': minimumLogMinutes,
      'requireLetOutType': requireLetOutType,
      'requireEarlyPutBackReason': requireEarlyPutBackReason,
      'requireName': requireName,
      'createLogsWhenUnderMinimumDuration': createLogsWhenUnderMinimumDuration,
      'showCustomForm': showCustomForm,
      'customFormURL': customFormURL,
      'appendAnimalDataToURL': appendAnimalDataToURL,
      'geofence': geofence?.toMap(), // Only include if not null
    };
  }

  // Factory constructor to create VolunteerSettings from Firestore Map
  factory VolunteerSettings.fromMap(Map<String, dynamic> data) {
FilterElement? mainFilter;
    if (data.containsKey('mainFilter') && data['mainFilter'] != null) {
      final mainFilterData = data['mainFilter'];
      if (mainFilterData is Map<String, dynamic> &&
          mainFilterData['type'] != null) {
        mainFilter =
            FilterElement.fromJson(Map<String, dynamic>.from(mainFilterData));
      } else {
        mainFilter = null;
      }
    } else {
      mainFilter = null;
    }

    return VolunteerSettings(
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      mainSort: data['mainSort'] ?? "None",
      mainFilter: mainFilter,
      allowBulkTakeOut: data['allowBulkTakeOut'] ?? false,
      minimumLogMinutes: data['minimumLogMinutes'] ?? 0,
      requireLetOutType: data['requireLetOutType'] ?? false,
      requireEarlyPutBackReason: data['requireEarlyPutBackReason'] ?? false,
      requireName: data['requireName'] ?? false,
      createLogsWhenUnderMinimumDuration:
          data['createLogsWhenUnderMinimumDuration'] ?? false,
      showCustomForm: data['showCustomForm'] ?? false,
      customFormURL: data['customFormURL'] ?? "",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
      geofence: data['geofence'] != null
          ? Geofence.fromMap(data['geofence'] as Map<String, dynamic>)
          : null, // Handle null geofence safely
    );
  }
}
