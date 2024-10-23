import 'package:shelter_partner/views/pages/main_filter_page.dart';

class DeviceSettings {
  final String mode;


  final bool photoUploadsAllowed;
  final String mainSort;
  final FilterElement? mainFilter;
  final FilterElement? visitorFilter;
  final String visitorSort;
  final bool allowBulkTakeOut;
  final int minimumLogMinutes;
  final bool requireLetOutType;
  final bool requireEarlyPutBackReason;
  final bool requireName;
  final bool createLogsWhenUnderMinimumDuration;
  final bool showNoteDates;
  final bool showLogs;
  final bool showCustomForm;
  final String customFormURL;
  final String buttonType;
  final bool appendAnimalDataToURL;

  DeviceSettings({
    required this.mode,
    required this.photoUploadsAllowed,
    required this.mainSort,
    required this.mainFilter,
    required this.visitorFilter,
    required this.visitorSort,
    required this.allowBulkTakeOut,
    required this.minimumLogMinutes,
    required this.requireLetOutType,
    required this.requireEarlyPutBackReason,
    required this.requireName,
    required this.createLogsWhenUnderMinimumDuration,
    required this.showNoteDates,
    required this.showLogs,
    required this.showCustomForm,
    required this.customFormURL,
    required this.buttonType,
    required this.appendAnimalDataToURL,
  });

  DeviceSettings copyWith({
  String? mode,
  bool? photoUploadsAllowed,
  String? mainSort,
  FilterElement? mainFilter,
  FilterElement? visitorFilter,
  String? visitorSort,
  bool? allowBulkTakeOut,
  int? minimumLogMinutes,
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
}) {
  return DeviceSettings(
    mode: mode ?? this.mode,
    photoUploadsAllowed: photoUploadsAllowed ?? this.photoUploadsAllowed,
    mainSort: mainSort ?? this.mainSort,
    mainFilter: mainFilter ?? this.mainFilter,
    visitorFilter: visitorFilter ?? this.visitorFilter,
    visitorSort: visitorSort ?? this.visitorSort,
    allowBulkTakeOut: allowBulkTakeOut ?? this.allowBulkTakeOut,
    minimumLogMinutes: minimumLogMinutes ?? this.minimumLogMinutes,
    requireLetOutType: requireLetOutType ?? this.requireLetOutType,
    requireEarlyPutBackReason:
        requireEarlyPutBackReason ?? this.requireEarlyPutBackReason,
    requireName: requireName ?? this.requireName,
    createLogsWhenUnderMinimumDuration:
        createLogsWhenUnderMinimumDuration ?? this.createLogsWhenUnderMinimumDuration,
    showNoteDates: showNoteDates ?? this.showNoteDates,
    showLogs: showLogs ?? this.showLogs,
    showCustomForm: showCustomForm ?? this.showCustomForm,
    customFormURL: customFormURL ?? this.customFormURL,
    buttonType: buttonType ?? this.buttonType,
    appendAnimalDataToURL: appendAnimalDataToURL ?? this.appendAnimalDataToURL,
  );
}


  // Convert DeviceSettings to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mode': mode,
      'photoUploadsAllowed': photoUploadsAllowed,
      'mainSort': mainSort,
      if (mainFilter != null) 'mainFilter': mainFilter!.toJson(),
      if (visitorFilter != null) 'visitorFilter': visitorFilter!.toJson(),
      'visitorSort': visitorSort,
      'allowBulkTakeOut': allowBulkTakeOut,
      'minimumLogMinutes': minimumLogMinutes,
      'requireLetOutType': requireLetOutType,
      'requireEarlyPutBackReason': requireEarlyPutBackReason,
      'requireName': requireName,
      'createLogsWhenUnderMinimumDuration': createLogsWhenUnderMinimumDuration,
      'showNoteDates': showNoteDates,
      'showLogs': showLogs,
      'showCustomForm': showCustomForm,
      'customFormURL': customFormURL,
      'buttonType': buttonType,
      'appendAnimalDataToURL': appendAnimalDataToURL,
    };
  }

  // Factory constructor to create DeviceSettings from Firestore Map
  factory DeviceSettings.fromMap(Map<String, dynamic> data) {
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

    FilterElement? mainFilter;
    if (data.containsKey('mainFilter') && data['mainFilter'] != null) {
      final mainFilterData = data['mainFilter'] as Map<String, dynamic>;
      mainFilter = reconstructFilterGroup(mainFilterData);
    } else {
      mainFilter = null;
    }

    FilterElement? visitorFilter;
    if (data.containsKey('visitorFilter') && data['visitorFilter'] != null) {
      final visitorFilterData = data['visitorFilter'] as Map<String, dynamic>;
      visitorFilter = reconstructFilterGroup(visitorFilterData);
    } else {
      visitorFilter = null;
    }

    return DeviceSettings(
      mode: data['mode'] ?? "Admin",
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      mainSort: data['mainSort'] ?? "Last Let Out",
      mainFilter: mainFilter,
      visitorFilter: visitorFilter,
      visitorSort: data['visitorSort'] ?? "Alphabetical",
      allowBulkTakeOut: data['allowBulkTakeOut'] ?? false,
      minimumLogMinutes: data['minimumLogMinutes'] ?? 0,
      requireLetOutType: data['requireLetOutType'] ?? false,
      requireEarlyPutBackReason: data['requireEarlyPutBackReason'] ?? false,
      requireName: data['requireName'] ?? false,
      createLogsWhenUnderMinimumDuration:
          data['createLogsWhenUnderMinimumDuration'] ?? false,
      showNoteDates: data['showNoteDates'] ?? false,
      showLogs: data['showLogs'] ?? false,
      showCustomForm: data['showCustomForm'] ?? false,
      customFormURL: data['customFormURL'] ?? "",
      buttonType: data['buttonType'] ?? "Unknown",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
    );
  }
}
