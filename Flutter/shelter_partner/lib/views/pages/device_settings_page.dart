import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/picker_view.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import 'package:shelter_partner/views/components/text_field_view.dart';
import 'package:shelter_partner/views/pages/georestriction_settings_page.dart';

class DeviceSettingsPage extends ConsumerStatefulWidget {
  const DeviceSettingsPage({super.key});

  @override
  _DeviceSettingsPageState createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends ConsumerState<DeviceSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterSettingsViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text("Device Settings"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text("Device Settings"),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        appBar: AppBar(
          title: const Text("Device Settings"),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: [
                        PickerView(
                          title: "Main Sort",
                          options: const ["Last Let Out", "Alphabetical"],
                          value: shelter?.deviceSettings.mainSort ??
                              "Last Let Out",
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue.isNotEmpty) {
                              ref
                                  .read(
                                      shelterSettingsViewModelProvider.notifier)
                                  .modifyDeviceSettingString(
                                      shelter!.id, "mainSort", newValue);
                            }
                          },
                        ),
                        PickerView(
                          title: "Secondary Sort",
                          options: const ["None", "Color", "Location"],
                          value:
                              shelter?.deviceSettings.secondarySort ?? "None",
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue.isNotEmpty) {
                              ref
                                  .read(
                                      shelterSettingsViewModelProvider.notifier)
                                  .modifyDeviceSettingString(
                                      shelter!.id, "secondarySort", newValue);
                            }
                          },
                        ),
                        PickerView(
                          title: "Group By",
                          options: const ["None"],
                          value: shelter?.deviceSettings.groupBy ?? "None",
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue.isNotEmpty) {
                              ref
                                  .read(
                                      shelterSettingsViewModelProvider.notifier)
                                  .modifyDeviceSettingString(
                                      shelter!.id, "groupBy", newValue);
                            }
                          },
                        ),
                        PickerView(
                          title: "Button Type",
                          options: const ["In App", "QR Code"],
                          value: shelter?.deviceSettings.buttonType ?? "In App",
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue.isNotEmpty) {
                              ref
                                  .read(
                                      shelterSettingsViewModelProvider.notifier)
                                  .modifyDeviceSettingString(
                                      shelter!.id, "buttonType", newValue);
                            }
                          },
                        ),
                      ]),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: [
                        TextFieldView(
                            title: "Custom Form URL",
                            hint: "Custom Form URL",
                            value:
                                shelter?.deviceSettings.customFormURL as String,
                            onSaved: (String value) {
                              ref
                                  .read(
                                      shelterSettingsViewModelProvider.notifier)
                                  .modifyDeviceSettingString(
                                      shelter!.id, "customFormURL", value);
                            }),
                      ]),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: [
                        NumberStepperView(
                          title: "Minimum Duration",
                          label: "minutes",
                          value: shelter?.deviceSettings.minimumLogMinutes ?? 0,
                          increment: () {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .incrementDeviceSetting(
                                    shelter!.id, "minimumLogMinutes");
                          },
                          decrement: () {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .decrementDeviceSetting(
                                    shelter!.id, "minimumLogMinutes");
                          },
                        ),
                        NumberStepperView(
                          title: "Automatic Put Back",
                          label: "hours",
                          value:
                              shelter?.deviceSettings.automaticPutBackHours ??
                                  0,
                          increment: () {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .incrementDeviceSetting(
                                    shelter!.id, "automaticPutBackHours");
                          },
                          decrement: () {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .decrementDeviceSetting(
                                    shelter!.id, "automaticPutBackHours");
                          },
                        ),
                      ]),
                    ),
                  ),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: [
                        SwitchToggleView(
                          title: "Admin Mode",
                          value: shelter?.deviceSettings.adminMode ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "adminMode");
                          },
                        ),
                        SwitchToggleView(
                          title: "Photo Uploads Allowed",
                          value: shelter?.deviceSettings.photoUploadsAllowed ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "photoUploadsAllowed");
                          },
                        ),
                        SwitchToggleView(
                          title: "Allow Bulk Take Out",
                          value:
                              shelter?.deviceSettings.allowBulkTakeOut ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "allowBulkTakeOut");
                          },
                        ),
                        SwitchToggleView(
                          title: "Automatically Put Back Animals",
                          value: shelter?.deviceSettings
                                  .automaticallyPutBackAnimals ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "automaticallyPutBackAnimals");
                          },
                        ),
                        SwitchToggleView(
                          title: "Ignore Visit When Automatically Put Back",
                          value: shelter?.deviceSettings
                                  .ignoreVisitWhenAutomaticallyPutBack ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id,
                                    "ignoreVisitWhenAutomaticallyPutBack");
                          },
                        ),
                        SwitchToggleView(
                          title: "Require Let Out Type",
                          value: shelter?.deviceSettings.requireLetOutType ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "requireLetOutType");
                          },
                        ),
                        SwitchToggleView(
                          title: "Require Early Put Back Reason",
                          value: shelter
                                  ?.deviceSettings.requireEarlyPutBackReason ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "requireEarlyPutBackReason");
                          },
                        ),
                        SwitchToggleView(
                          title: "Require Name",
                          value: shelter?.deviceSettings.requireName ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "requireName");
                          },
                        ),
                        SwitchToggleView(
                          title: "Create Logs When Under Minimum Duration",
                          value: shelter?.deviceSettings
                                  .createLogsWhenUnderMinimumDuration ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id,
                                    "createLogsWhenUnderMinimumDuration");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show Note Dates",
                          value: shelter?.deviceSettings.showNoteDates ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showNoteDates");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show Logs",
                          value: shelter?.deviceSettings.showLogs ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showLogs");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show All Animals",
                          value:
                              shelter?.deviceSettings.showAllAnimals ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showAllAnimals");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show Search Bar",
                          value: shelter?.deviceSettings.showSearchBar ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showSearchBar");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show Filter",
                          value: shelter?.deviceSettings.showFilter ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showFilter");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show Custom Form",
                          value:
                              shelter?.deviceSettings.showCustomForm ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showCustomForm");
                          },
                        ),
                        SwitchToggleView(
                          title: "Append Animal Data To URL",
                          value:
                              shelter?.deviceSettings.appendAnimalDataToURL ??
                                  false,
                          onChanged: (bool newValue) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "appendAnimalDataToURL");
                          },
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
