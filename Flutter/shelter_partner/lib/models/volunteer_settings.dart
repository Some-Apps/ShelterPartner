import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/models/geofence.dart';

class VolunteerSettings {
  final bool photoUploadsAllowed;
  final String enrichmentSort;
  final FilterElement? enrichmentFilter;
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
    required this.enrichmentSort,
    required this.enrichmentFilter,
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
      'enrichmentSort;': enrichmentSort,
      'enrichmentFilter': enrichmentFilter,
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
FilterElement? enrichmentFilter;
    if (data.containsKey('enrichmentFilter') && data['enrichmentFilter'] != null) {
      final enrichmentFilterData = data['enrichmentFilter'];
      if (enrichmentFilterData is Map<String, dynamic> &&
          enrichmentFilterData['type'] != null) {
        enrichmentFilter =
            FilterElement.fromJson(Map<String, dynamic>.from(enrichmentFilterData));
      } else {
        enrichmentFilter = null;
      }
    } else {
      enrichmentFilter = null;
    }

    return VolunteerSettings(
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      enrichmentSort: data['enrichmentSort;'] ?? "None",
      enrichmentFilter: enrichmentFilter,
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
