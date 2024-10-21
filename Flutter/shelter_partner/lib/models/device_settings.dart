import 'package:shelter_partner/views/pages/main_filter_page.dart';

class DeviceSettings {
  final bool adminMode;

// instead of adminMode, have it be mode and have the options be admin, volunteer, visitor, or volunteerAndVisitor

  final bool photoUploadsAllowed;
  final String mainSort;
  final FilterElement? mainFilter;
  final String visitorSort;
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
  final bool showCustomForm;
  final String customFormURL;
  final String buttonType;
  final bool appendAnimalDataToURL;

  DeviceSettings({
    required this.adminMode,
    required this.photoUploadsAllowed,
    required this.mainSort,
    required this.mainFilter,
    required this.visitorSort,
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
    required this.showCustomForm,
    required this.customFormURL,
    required this.buttonType,
    required this.appendAnimalDataToURL,
  });

  DeviceSettings copyWith(Map<String, dynamic> changes) {
    return DeviceSettings(
      adminMode:
          changes.containsKey('adminMode') ? changes['adminMode'] : adminMode,
      photoUploadsAllowed: changes.containsKey('photoUploadsAllowed')
          ? changes['photoUploadsAllowed']
          : photoUploadsAllowed,
      mainSort:
          changes.containsKey('mainSort') ? changes['mainSort'] : mainSort,
      mainFilter: changes.containsKey('mainFilter')
          ? changes['mainFilter']
          : mainFilter,
      visitorSort: changes.containsKey('visitorSort')
          ? changes['visitorSort']
          : visitorSort,
      allowBulkTakeOut: changes.containsKey('allowBulkTakeOut')
          ? changes['allowBulkTakeOut']
          : allowBulkTakeOut,
      minimumLogMinutes: changes.containsKey('minimumLogMinutes')
          ? changes['minimumLogMinutes']
          : minimumLogMinutes,
      automaticallyPutBackAnimals:
          changes.containsKey('automaticallyPutBackAnimals')
              ? changes['automaticallyPutBackAnimals']
              : automaticallyPutBackAnimals,
      ignoreVisitWhenAutomaticallyPutBack:
          changes.containsKey('ignoreVisitWhenAutomaticallyPutBack')
              ? changes['ignoreVisitWhenAutomaticallyPutBack']
              : ignoreVisitWhenAutomaticallyPutBack,
      automaticPutBackHours: changes.containsKey('automaticPutBackHours')
          ? changes['automaticPutBackHours']
          : automaticPutBackHours,
      requireLetOutType: changes.containsKey('requireLetOutType')
          ? changes['requireLetOutType']
          : requireLetOutType,
      requireEarlyPutBackReason:
          changes.containsKey('requireEarlyPutBackReason')
              ? changes['requireEarlyPutBackReason']
              : requireEarlyPutBackReason,
      requireName: changes.containsKey('requireName')
          ? changes['requireName']
          : requireName,
      createLogsWhenUnderMinimumDuration:
          changes.containsKey('createLogsWhenUnderMinimumDuration')
              ? changes['createLogsWhenUnderMinimumDuration']
              : createLogsWhenUnderMinimumDuration,
      showNoteDates: changes.containsKey('showNoteDates')
          ? changes['showNoteDates']
          : showNoteDates,
      showLogs:
          changes.containsKey('showLogs') ? changes['showLogs'] : showLogs,
      showCustomForm: changes.containsKey('showCustomForm')
          ? changes['showCustomForm']
          : showCustomForm,
      customFormURL: changes.containsKey('customFormURL')
          ? changes['customFormURL']
          : customFormURL,
      buttonType: changes.containsKey('buttonType')
          ? changes['buttonType']
          : buttonType,
      appendAnimalDataToURL: changes.containsKey('appendAnimalDataToURL')
          ? changes['appendAnimalDataToURL']
          : appendAnimalDataToURL,
    );
  }

  // Convert DeviceSettings to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'adminMode': adminMode,
      'photoUploadsAllowed': photoUploadsAllowed,
      'mainSort': mainSort,
      if (mainFilter != null) 'mainFilter': mainFilter!.toJson(),
      'visitorSort': visitorSort,
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

    return DeviceSettings(
      adminMode: data['adminMode'] ?? false,
      photoUploadsAllowed: data['photoUploadsAllowed'] ?? false,
      mainSort: data['mainSort'] ?? "Unknown",
      mainFilter: mainFilter,
      visitorSort: data['visitorSort'] ?? "Unknown",
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
      showCustomForm: data['showCustomForm'] ?? false,
      customFormURL: data['customFormURL'] ?? "",
      buttonType: data['buttonType'] ?? "Unknown",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
    );
  }
}
