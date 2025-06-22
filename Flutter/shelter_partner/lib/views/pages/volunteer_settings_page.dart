import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/picker_view.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import 'package:shelter_partner/views/pages/georestriction_settings_page.dart';

class VolunteerSettingsPage extends ConsumerStatefulWidget {
  const VolunteerSettingsPage({super.key});

  @override
  _VolunteerSettingsPageState createState() => _VolunteerSettingsPageState();
}

class _VolunteerSettingsPageState extends ConsumerState<VolunteerSettingsPage> {
  late TextEditingController _customFormURLController;

  @override
  void initState() {
    super.initState();
    _customFormURLController = TextEditingController();
  }

  @override
  void dispose() {
    _customFormURLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(volunteersViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text("Volunteer Settings")),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text("Volunteer Settings")),
        body: Center(child: Text('Error: $error')),
      ),
      data: (shelter) {
        _customFormURLController.text =
            shelter?.volunteerSettings.customFormURL ?? "";

        return Scaffold(
          appBar: AppBar(title: const Text("Volunteer Settings")),
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card.outlined(
                          child: Column(
                            children: [
                              PickerView(
                                title: "Enrichment Sort",
                                options: const ["Last Let Out", "Alphabetical"],
                                value:
                                    (shelter
                                                ?.volunteerSettings
                                                .enrichmentSort !=
                                            null &&
                                        [
                                          "Last Let Out",
                                          "Alphabetical",
                                        ].contains(
                                          shelter
                                              ?.volunteerSettings
                                              .enrichmentSort,
                                        ))
                                    ? shelter?.volunteerSettings.enrichmentSort
                                    : "Last Let Out",
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue.isNotEmpty) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .modifyVolunteerSettingString(
                                          shelter!.id,
                                          "enrichmentSort",
                                          newValue,
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Card.outlined(
                          child: NavigationButton(
                            title: "Enrichment Filter",
                            route: '/volunteers/volunteer-settings/main-filter',
                            extra: FilterParameters(
                              title: "Volunteers Enrichment Filter",
                              collection: 'shelters',
                              documentID: shelterAsyncValue.value!.id,
                              filterFieldPath:
                                  'volunteerSettings.enrichmentFilter',
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Card.outlined(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: "Custom Form URL",
                                hintText: "Custom Form URL",
                              ),
                              controller: _customFormURLController,
                              onChanged: (String value) {
                                ref
                                    .read(volunteersViewModelProvider.notifier)
                                    .modifyVolunteerSettingString(
                                      shelter!.id,
                                      "customFormURL",
                                      value,
                                    );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Card.outlined(
                          child: ListTile(
                            title: NumberStepperView(
                              title: "Minimum Duration",
                              label: "minutes",
                              minValue: 1,
                              maxValue: 600,
                              value:
                                  shelter
                                      ?.volunteerSettings
                                      .minimumLogMinutes ??
                                  0,
                              increment: () {
                                ref
                                    .read(volunteersViewModelProvider.notifier)
                                    .incrementAttribute(
                                      shelter!.id,
                                      "minimumLogMinutes",
                                    );
                              },
                              decrement: () {
                                ref
                                    .read(volunteersViewModelProvider.notifier)
                                    .decrementAttribute(
                                      shelter!.id,
                                      "minimumLogMinutes",
                                    );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Card.outlined(
                          child: Column(
                            children: [
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Photo Uploads Allowed",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .photoUploadsAllowed ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "photoUploadsAllowed",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Allow Bulk Take Out",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .allowBulkTakeOut ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "allowBulkTakeOut",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Require Let Out Type",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .requireLetOutType ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "requireLetOutType",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Require Early Put Back Reason",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .requireEarlyPutBackReason ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "requireEarlyPutBackReason",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Require Name",
                                  value:
                                      shelter?.volunteerSettings.requireName ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "requireName",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: SwitchToggleView(
                                  title:
                                      "Create Logs When Under Minimum Duration",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .createLogsWhenUnderMinimumDuration ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "createLogsWhenUnderMinimumDuration",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Show Custom Form",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .showCustomForm ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "showCustomForm",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Append Animal Data To URL",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .appendAnimalDataToURL ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "appendAnimalDataToURL",
                                        );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Card.outlined(
                          child: Column(
                            children: [
                              ListTile(
                                title: SwitchToggleView(
                                  title: "Georestrict",
                                  value:
                                      shelter
                                          ?.volunteerSettings
                                          .geofence
                                          ?.isEnabled ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          volunteersViewModelProvider.notifier,
                                        )
                                        .toggleAttribute(
                                          shelter!.id,
                                          "geofence.isEnabled",
                                        );
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: const Text("Georestriction Settings"),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const GeorestrictionSettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
