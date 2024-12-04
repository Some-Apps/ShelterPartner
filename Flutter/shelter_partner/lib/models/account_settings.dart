import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';

class AccountSettings {
  final String mode;


  final bool photoUploadsAllowed;
  final String enrichmentSort;
  final FilterElement? enrichmentFilter;
  final FilterElement? visitorFilter;
  final String visitorSort;
  final String slideshowSize;
  final bool allowBulkTakeOut;
  final int minimumLogMinutes;
  final int slideshowTimer;
  final bool requireLetOutType;
  final bool requireEarlyPutBackReason;
  final bool requireName;
  final bool createLogsWhenUnderMinimumDuration;
  final bool showCustomForm;
  final String customFormURL;
  final String buttonType;
  final bool appendAnimalDataToURL;
  final bool removeAds;

  final bool simplisticMode;

  AccountSettings({
    required this.mode,
    required this.photoUploadsAllowed,
    required this.enrichmentSort,
    required this.enrichmentFilter,
    required this.visitorFilter,
    required this.visitorSort,
    required this.slideshowSize,
    required this.allowBulkTakeOut,
    required this.minimumLogMinutes,
    required this.slideshowTimer,
    required this.requireLetOutType,
    required this.requireEarlyPutBackReason,
    required this.requireName,
    required this.createLogsWhenUnderMinimumDuration,
    required this.showCustomForm,
    required this.customFormURL,
    required this.buttonType,
    required this.appendAnimalDataToURL,
    required this.removeAds,

    required this.simplisticMode,
  });

  AccountSettings copyWith({
  String? mode,
  bool? photoUploadsAllowed,
  String? enrichmentSort,
  FilterElement? enrichmentFilter,
  FilterElement? visitorFilter,
  String? visitorSort,
  String? slideshowSize,
  bool? allowBulkTakeOut,
  int? minimumLogMinutes,
  int? slideshowTimer,
  bool? requireLetOutType,
  bool? requireEarlyPutBackReason,
  bool? requireName,
  bool? createLogsWhenUnderMinimumDuration,
  bool? showNoteDates,
  bool? showLogs,
  bool? showCustomForm,
  String? customFormURL,
  String? buttonType,
  bool? appendAnimalDataToURL,
  bool? removeAds,

  bool? simplisticMode,
}) {
  return AccountSettings(
    mode: mode ?? this.mode,
    photoUploadsAllowed: photoUploadsAllowed ?? this.photoUploadsAllowed,
    enrichmentSort: enrichmentSort ?? this.enrichmentSort,
    enrichmentFilter: enrichmentFilter ?? this.enrichmentFilter,
    visitorFilter: visitorFilter ?? this.visitorFilter,
    visitorSort: visitorSort ?? this.visitorSort,
    slideshowSize: slideshowSize ?? this.slideshowSize,
    allowBulkTakeOut: allowBulkTakeOut ?? this.allowBulkTakeOut,
    minimumLogMinutes: minimumLogMinutes ?? this.minimumLogMinutes,
    slideshowTimer: slideshowTimer ?? this.slideshowTimer,
    requireLetOutType: requireLetOutType ?? this.requireLetOutType,
    requireEarlyPutBackReason:
        requireEarlyPutBackReason ?? this.requireEarlyPutBackReason,
    requireName: requireName ?? this.requireName,
    createLogsWhenUnderMinimumDuration:
        createLogsWhenUnderMinimumDuration ?? this.createLogsWhenUnderMinimumDuration,
    showCustomForm: showCustomForm ?? this.showCustomForm,
    customFormURL: customFormURL ?? this.customFormURL,
    buttonType: buttonType ?? this.buttonType,
    appendAnimalDataToURL: appendAnimalDataToURL ?? this.appendAnimalDataToURL,
    removeAds: removeAds ?? this.removeAds,

    simplisticMode: simplisticMode ?? this.simplisticMode,
  );
}


  // Convert AccountSettings to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mode': mode,
      'photoUploadsAllowed': photoUploadsAllowed,
      'enrichmentSort': enrichmentSort,
      if (enrichmentFilter != null) 'enrichmentFilter': enrichmentFilter!.toJson(),
      if (visitorFilter != null) 'visitorFilter': visitorFilter!.toJson(),
      'visitorSort': visitorSort,
      'slideshowSize': slideshowSize,
      'allowBulkTakeOut': allowBulkTakeOut,
      'minimumLogMinutes': minimumLogMinutes,
      'slideshowTimer': slideshowTimer,
      'requireLetOutType': requireLetOutType,
      'requireEarlyPutBackReason': requireEarlyPutBackReason,
      'requireName': requireName,
      'createLogsWhenUnderMinimumDuration': createLogsWhenUnderMinimumDuration,
      'showCustomForm': showCustomForm,
      'customFormURL': customFormURL,
      'buttonType': buttonType,
      'appendAnimalDataToURL': appendAnimalDataToURL,
      'removeAds': removeAds,

      'simplisticMode': simplisticMode,
    };
  }

  // Factory constructor to create AccountSettings from Firestore Map
  factory AccountSettings.fromMap(Map<String, dynamic> data) {
    FilterGroup reconstructFilterGroup(Map<String, dynamic> json) {
      List<FilterElement> elements = [];
      if (json.containsKey('filterElements')) {
        elements = (json['filterElements'] as List)
            .map((e) => FilterElement.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      LogicalOperator logicalOperator =
          LogicalOperator.and; // Default or derive from data
      if (json.containsKey('operatorsBetween') &&
          (json['operatorsBetween'] as Map).values.any((v) => v == 'or')) {
        logicalOperator = LogicalOperator.or;
      }

      return FilterGroup(
        logicalOperator: logicalOperator,
        elements: elements,
      );
    }

    FilterElement? enrichmentFilter;
    if (data.containsKey('enrichmentFilter') && data['enrichmentFilter'] != null) {
      final enrichmentFilterData = data['enrichmentFilter'] as Map<String, dynamic>;
      enrichmentFilter = reconstructFilterGroup(enrichmentFilterData);
    } else {
      enrichmentFilter = null;
    }

    FilterElement? visitorFilter;
    if (data.containsKey('visitorFilter') && data['visitorFilter'] != null) {
      final visitorFilterData = data['visitorFilter'] as Map<String, dynamic>;
      visitorFilter = reconstructFilterGroup(visitorFilterData);
    } else {
      visitorFilter = null;
    }

    return AccountSettings(
      mode: data['mode'] ?? "Admin",
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      enrichmentSort: data['enrichmentSort'] ?? "Last Let Out",
      enrichmentFilter: enrichmentFilter,
      visitorFilter: visitorFilter,
      visitorSort: data['visitorSort'] ?? "Alphabetical",
      slideshowSize: data['slideshowSize'] ?? "Scaled to Fit",
      allowBulkTakeOut: data['allowBulkTakeOut'] ?? false,
      minimumLogMinutes: data['minimumLogMinutes'] ?? 0,
      slideshowTimer: data['slideshowTimer'] ?? 0,
      requireLetOutType: data['requireLetOutType'] ?? false,
      requireEarlyPutBackReason: data['requireEarlyPutBackReason'] ?? false,
      requireName: data['requireName'] ?? false,
      createLogsWhenUnderMinimumDuration:
          data['createLogsWhenUnderMinimumDuration'] ?? false,
      showCustomForm: data['showCustomForm'] ?? false,
      customFormURL: data['customFormURL'] ?? "",
      buttonType: data['buttonType'] ?? "Unknown",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
      removeAds: data['removeAds'] ?? false,

      simplisticMode: data['simplisticMode'] ?? true,
    );
  }
}
