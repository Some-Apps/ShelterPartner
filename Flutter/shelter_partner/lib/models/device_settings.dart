import 'package:shelter_partner/models/scheduled_report.dart';

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
  final String customFormURL;
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
      'customFormURL': customFormURL,
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
      customFormURL: data['customFormURL'] ?? "",
      buttonType: data['buttonType'] ?? "Unknown",
      appendAnimalDataToURL: data['appendAnimalDataToURL'] ?? false,
    );
  }
}