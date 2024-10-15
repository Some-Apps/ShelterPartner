import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/picker_view.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import 'package:shelter_partner/views/components/text_field_view.dart';
import 'package:shelter_partner/views/pages/georestriction_settings_page.dart';

class VolunteerSettingsPage extends ConsumerStatefulWidget {
  const VolunteerSettingsPage({super.key});

  @override
  _VolunteerSettingsPageState createState() => _VolunteerSettingsPageState();
}

class _VolunteerSettingsPageState extends ConsumerState<VolunteerSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(volunteersViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text("Volunteer Settings"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text("Volunteer Settings"),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        appBar: AppBar(
          title: const Text("Volunteer Settings"),
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
                          value: shelter?.volunteerSettings.mainSort ??
                              "Last Let Out",
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue.isNotEmpty) {
                              ref
                                  .read(volunteersViewModelProvider.notifier)
                                  .modifyVolunteerSettingString(
                                      shelter!.id, "mainSort", newValue);
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
                            value: shelter?.volunteerSettings.customFormURL
                                    as String ??
                                "",
                            onSaved: (String value) {
                              ref
                                  .read(volunteersViewModelProvider.notifier)
                                  .modifyVolunteerSettingString(
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
                          value:
                              shelter?.volunteerSettings.minimumLogMinutes ?? 0,
                          increment: () {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .incrementAttribute(
                                    shelter!.id, "minimumLogMinutes");
                          },
                          decrement: () {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .decrementAttribute(
                                    shelter!.id, "minimumLogMinutes");
                          },
                        ),
                        NumberStepperView(
                          title: "Automatic Put Back",
                          label: "hours",
                          value: shelter
                                  ?.volunteerSettings.automaticPutBackHours ??
                              0,
                          increment: () {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .incrementAttribute(
                                    shelter!.id, "automaticPutBackHours");
                          },
                          decrement: () {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .decrementAttribute(
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
                          title: "Photo Uploads Allowed",
                          value:
                              shelter?.volunteerSettings.photoUploadsAllowed ??
                                  false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "photoUploadsAllowed");
                          },
                        ),
                        SwitchToggleView(
                          title: "Allow Bulk Take Out",
                          value: shelter?.volunteerSettings.allowBulkTakeOut ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "allowBulkTakeOut");
                          },
                        ),
                        SwitchToggleView(
                          title: "Automatically Put Back Animals",
                          value: shelter?.volunteerSettings
                                  .automaticallyPutBackAnimals ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "automaticallyPutBackAnimals");
                          },
                        ),
                        SwitchToggleView(
                          title: "Ignore Visit When Automatically Put Back",
                          value: shelter?.volunteerSettings
                                  .ignoreVisitWhenAutomaticallyPutBack ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id,
                                    "ignoreVisitWhenAutomaticallyPutBack");
                          },
                        ),
                        SwitchToggleView(
                          title: "Require Let Out Type",
                          value: shelter?.volunteerSettings.requireLetOutType ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "requireLetOutType");
                          },
                        ),
                        SwitchToggleView(
                          title: "Require Early Put Back Reason",
                          value: shelter?.volunteerSettings
                                  .requireEarlyPutBackReason ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "requireEarlyPutBackReason");
                          },
                        ),
                        SwitchToggleView(
                          title: "Require Name",
                          value:
                              shelter?.volunteerSettings.requireName ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "requireName");
                          },
                        ),
                        SwitchToggleView(
                          title: "Create Logs When Under Minimum Duration",
                          value: shelter?.volunteerSettings
                                  .createLogsWhenUnderMinimumDuration ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id,
                                    "createLogsWhenUnderMinimumDuration");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show Note Dates",
                          value:
                              shelter?.volunteerSettings.showNoteDates ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showNoteDates");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show Logs",
                          value: shelter?.volunteerSettings.showLogs ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showLogs");
                          },
                        ),
                        SwitchToggleView(
                          title: "Show All Animals",
                          value: shelter?.volunteerSettings.showAllAnimals ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showAllAnimals");
                          },
                        ),
                    
                        SwitchToggleView(
                          title: "Show Custom Form",
                          value: shelter?.volunteerSettings.showCustomForm ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(shelter!.id, "showCustomForm");
                          },
                        ),
                        SwitchToggleView(
                          title: "Append Animal Data To URL",
                          value: shelter
                                  ?.volunteerSettings.appendAnimalDataToURL ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(volunteersViewModelProvider.notifier)
                                .toggleAttribute(
                                    shelter!.id, "appendAnimalDataToURL");
                          },
                        ),
                      ]),
                    ),
                  ),
                    Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                      children: [
                        SwitchToggleView(
                        title: "Georestrict",
                        value: shelter?.volunteerSettings.geofence?.isEnabled ?? false,
                        onChanged: (bool newValue) {
                          ref
                            .read(volunteersViewModelProvider.notifier)
                            .toggleAttribute(shelter!.id, "geofence.isEnabled");
                        },
                        ),
                        ListTile(
                        title: const Text("Georestriction Settings"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GeorestrictionSettingsPage(),
                          ),
                          );
                        },
                        ),
                      ],
                      ),
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
