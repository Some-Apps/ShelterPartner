import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/picker_view.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';

class DeviceSettingsPage extends ConsumerStatefulWidget {
  const DeviceSettingsPage({super.key});

  @override
  _DeviceSettingsPageState createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends ConsumerState<DeviceSettingsPage> {
  final FocusNode _focusNode = FocusNode();

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
    final shelterAsyncValue = ref.watch(deviceSettingsViewModelProvider);

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: shelterAsyncValue.when(
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
        data: (user) {
          _customFormURLController.text = user?.deviceSettings?.customFormURL ?? "";
          return Scaffold(

          appBar: AppBar(
            title: const Text("Device Settings"),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 25.0),
                  Card.outlined(
                    child: Column(children: [
                      PickerView(
                        title: "Main Sort",
                        options: const ["Last Let Out", "Alphabetical"],
                        value: user?.deviceSettings?.mainSort ?? "Last Let Out",
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .modifyDeviceSettingString(
                                    user!.id, "mainSort", newValue);
                          }
                        },
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      PickerView(
                        title: "Visitor Sort",
                        options: const ["Intake Date", "Alphabetical"],
                        value:
                            user?.deviceSettings?.visitorSort ?? "Alphabetical",
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .modifyDeviceSettingString(
                                    user!.id, "visitorSort", newValue);
                          }
                        },
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      PickerView(
                        title: "Mode",
                        options: const [
                          "Admin",
                          "Volunteer",
                          "Visitor",
                          "Volunteer & Visitor"
                        ],
                        value: user?.deviceSettings?.mode ?? "Admin",
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue.isNotEmpty) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .modifyDeviceSettingString(
                                    user!.id, "mode", newValue);

                            final appUser =
                                ref.read(appUserProvider.notifier).state;
                            final updatedAppUser = appUser!.copyWith(
                              deviceSettings: appUser.deviceSettings
                                  ?.copyWith(mode: newValue),
                            );

                            if (context.mounted && newValue != 'Visitor') {
                              context.go('/animals');
                            } else {
                              context.go('/visitors');
                            }

                            // Update the provider with the new state
                            ref.read(appUserProvider.notifier).state =
                                updatedAppUser;
                          }
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 25.0),

                  Card.outlined(
                    child: NavigationButton(
                      title: "Main Filter",
                      route: '/settings/device-settings/main-filter',
                      extra: FilterParameters(
                        title: "Device Animals Filter",
                        collection: 'users',
                        documentID: shelterAsyncValue.value!.id,
                        filterFieldPath: 'deviceSettings.mainFilter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 25.0),

                  Card.outlined(
                    child: NavigationButton(
                      title: "Visitor Filter",
                      route: '/settings/device-settings/visitor-filter',
                      extra: FilterParameters(
                        title: "Device Visitor Filter",
                        collection: 'users',
                        documentID: shelterAsyncValue.value!.id,
                        filterFieldPath: 'deviceSettings.visitorFilter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 25.0),

                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: "Custom Form URL",
                          hintText: "Custom Form URL",
                        ),
                        controller: _customFormURLController,
                        focusNode: _focusNode,
                        onChanged: (String value) {
                          ref
                              .read(deviceSettingsViewModelProvider.notifier)
                              .modifyDeviceSettingString(user!.id, "customFormURL", value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 25.0),

                  Card.outlined(
                    child: ListTile(
                      title: NumberStepperView(
                        title: "Minimum Duration",
                        label: "minutes",
                        value: user?.deviceSettings?.minimumLogMinutes ?? 0,
                        increment: () {
                          ref
                              .read(deviceSettingsViewModelProvider.notifier)
                              .incrementAttribute(user!.id, "minimumLogMinutes");
                        },
                        decrement: () {
                          ref
                              .read(deviceSettingsViewModelProvider.notifier)
                              .decrementAttribute(user!.id, "minimumLogMinutes");
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 25.0),

                  Card.outlined(
                    child: Column(children: [
                      ListTile(
                        title: SwitchToggleView(
                          title: "Photo Uploads Allowed",
                          value:
                              user?.deviceSettings?.photoUploadsAllowed ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(user!.id, "photoUploadsAllowed");
                          },
                        ),
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      ListTile(
                        title: SwitchToggleView(
                          title: "Allow Bulk Take Out",
                          value: user?.deviceSettings?.allowBulkTakeOut ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(user!.id, "allowBulkTakeOut");
                          },
                        ),
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      ListTile(
                        title: SwitchToggleView(
                          title: "Require Let Out Type",
                          value: user?.deviceSettings?.requireLetOutType ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(user!.id, "requireLetOutType");
                          },
                        ),
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      ListTile(
                        title: SwitchToggleView(
                          title: "Require Early Put Back Reason",
                          value:
                              user?.deviceSettings?.requireEarlyPutBackReason ??
                                  false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    user!.id, "requireEarlyPutBackReason");
                          },
                        ),
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      ListTile(
                        title: SwitchToggleView(
                          title: "Require Name",
                          value: user?.deviceSettings?.requireName ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(user!.id, "requireName");
                          },
                        ),
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      ListTile(
                        title: SwitchToggleView(
                          title: "Create Logs When Under Minimum Duration",
                          value: user?.deviceSettings
                                  ?.createLogsWhenUnderMinimumDuration ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(user!.id,
                                    "createLogsWhenUnderMinimumDuration");
                          },
                        ),
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      ListTile(
                        title: SwitchToggleView(
                          title: "Show Custom Form",
                          value: user?.deviceSettings?.showCustomForm ?? false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(user!.id, "showCustomForm");
                          },
                        ),
                      ),
                      Divider(
                        color: Colors.black.withOpacity(0.1),
                        height: 0,
                        thickness: 1,
                      ),
                      ListTile(
                        title: SwitchToggleView(
                          title: "Append Animal Data To URL",
                          value: user?.deviceSettings?.appendAnimalDataToURL ??
                              false,
                          onChanged: (bool newValue) {
                            ref
                                .read(deviceSettingsViewModelProvider.notifier)
                                .toggleAttribute(
                                    user!.id, "appendAnimalDataToURL");
                          },
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
}