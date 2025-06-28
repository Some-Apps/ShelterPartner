import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/models/filter_parameters.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/picker_view.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  AccountSettingsPageState createState() => AccountSettingsPageState();
}

class AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
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
    final shelterAsyncValue = ref.watch(accountSettingsViewModelProvider);

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: shelterAsyncValue.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text("Account Settings")),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text("Account Settings")),
          body: Center(child: Text('Error: $error')),
        ),
        data: (user) {
          _customFormURLController.text =
              user?.accountSettings?.customFormURL ?? "";
          return Scaffold(
            appBar: AppBar(title: const Text("Account Settings")),
            body: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 25.0),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            "General",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Card.outlined(
                          child: Column(
                            children: [
                              PickerView(
                                title: "Mode",
                                options: const [
                                  "Admin",
                                  "Enrichment",
                                  "Visitor",
                                  "Enrichment & Visitor",
                                ],
                                value: user?.accountSettings?.mode ?? "Admin",
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue.isNotEmpty) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .modifyAccountSettingString(
                                          user!.id,
                                          "mode",
                                          newValue,
                                        );

                                    final appUser = ref
                                        .read(appUserProvider.notifier)
                                        .state;
                                    final updatedAppUser = appUser!.copyWith(
                                      accountSettings: appUser.accountSettings
                                          ?.copyWith(mode: newValue),
                                    );

                                    if (context.mounted &&
                                        newValue != 'Visitor') {
                                      context.go('/enrichment');
                                    } else {
                                      context.go('/visitors');
                                    }

                                    // Update the provider with the new state
                                    ref.read(appUserProvider.notifier).state =
                                        updatedAppUser;
                                  }
                                },
                              ),

                              // ListTile(
                              //   title: SwitchToggleView(
                              //     title: "Remove Ads",
                              //     value:
                              //         user?.accountSettings?.removeAds ?? false,
                              //     onChanged: (bool newValue) {
                              //       ref
                              //           .read(accountSettingsViewModelProvider
                              //               .notifier)
                              //           .toggleAttribute(user!.id, "removeAds");
                              //     },
                              //   ),
                              //   subtitle: const Text(
                              //       "Just for testing. Not in final app."),
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        // Enrichment
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            "Enrichment",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Card.outlined(
                          child: Column(
                            children: [
                              PickerView(
                                title: "Enrichment Sort",
                                options: const ["Last Let Out", "Alphabetical"],
                                value:
                                    user?.accountSettings?.enrichmentSort ??
                                    "Last Let Out",
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue.isNotEmpty) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .modifyAccountSettingString(
                                          user!.id,
                                          "enrichmentSort",
                                          newValue,
                                        );
                                  }
                                },
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              NavigationButton(
                                title: "Enrichment Filter",
                                route: '/settings/account-settings/main-filter',
                                extra: FilterParameters(
                                  title: "Account Enrichment Filter",
                                  collection: 'users',
                                  documentID: shelterAsyncValue.value!.id,
                                  filterFieldPath:
                                      'accountSettings.enrichmentFilter',
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              Padding(
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
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .modifyAccountSettingString(
                                          user!.id,
                                          "customFormURL",
                                          value,
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
                                title: NumberStepperView(
                                  title: "Minimum Duration",
                                  label: "minutes",
                                  minValue: 1,
                                  maxValue: 600,
                                  value:
                                      user
                                          ?.accountSettings
                                          ?.minimumLogMinutes ??
                                      0,
                                  increment: () {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .incrementAttribute(
                                          user!.id,
                                          "minimumLogMinutes",
                                        );
                                  },
                                  decrement: () {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .decrementAttribute(
                                          user!.id,
                                          "minimumLogMinutes",
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
                                  title: "Photo Uploads Allowed",
                                  value:
                                      user
                                          ?.accountSettings
                                          ?.photoUploadsAllowed ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
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
                                      user?.accountSettings?.allowBulkTakeOut ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
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
                                      user
                                          ?.accountSettings
                                          ?.requireLetOutType ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
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
                                      user
                                          ?.accountSettings
                                          ?.requireEarlyPutBackReason ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
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
                                      user?.accountSettings?.requireName ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
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
                                      user
                                          ?.accountSettings
                                          ?.createLogsWhenUnderMinimumDuration ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
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
                                      user?.accountSettings?.showCustomForm ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
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
                                      user
                                          ?.accountSettings
                                          ?.appendAnimalDataToURL ??
                                      false,
                                  onChanged: (bool newValue) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .toggleAttribute(
                                          user!.id,
                                          "appendAnimalDataToURL",
                                        );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25.0),

                        const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            "Visitor",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Card.outlined(
                          child: Column(
                            children: [
                              PickerView(
                                title: "Visitor Sort",
                                options: const ["Intake Date", "Alphabetical"],
                                value:
                                    user?.accountSettings?.visitorSort ??
                                    "Alphabetical",
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue.isNotEmpty) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .modifyAccountSettingString(
                                          user!.id,
                                          "visitorSort",
                                          newValue,
                                        );
                                  }
                                },
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              NavigationButton(
                                title: "Visitor Filter",
                                route:
                                    '/settings/account-settings/visitor-filter',
                                extra: FilterParameters(
                                  title: "Account Visitor Filter",
                                  collection: 'users',
                                  documentID: shelterAsyncValue.value!.id,
                                  filterFieldPath:
                                      'accountSettings.visitorFilter',
                                ),
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              PickerView(
                                title: "Slideshow Size",
                                options: const [
                                  "Scaled to Fit",
                                  "Scaled to Fill",
                                  "Cropped to Square",
                                ],
                                value:
                                    user?.accountSettings?.slideshowSize ??
                                    "Scaled to Fit",
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue.isNotEmpty) {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .modifyAccountSettingString(
                                          user!.id,
                                          "slideshowSize",
                                          newValue,
                                        );

                                    final appUser = ref
                                        .read(appUserProvider.notifier)
                                        .state;
                                    final updatedAppUser = appUser!.copyWith(
                                      accountSettings: appUser.accountSettings
                                          ?.copyWith(slideshowSize: newValue),
                                    );

                                    // Update the provider with the new state
                                    ref.read(appUserProvider.notifier).state =
                                        updatedAppUser;
                                  }
                                },
                              ),
                              Divider(
                                color: Colors.black.withValues(alpha: 0.1),
                                height: 0,
                                thickness: 1,
                              ),
                              ListTile(
                                title: NumberStepperView(
                                  title: "Slideshow Timer",
                                  label: "seconds",
                                  minValue: 5,
                                  maxValue: 600,
                                  value:
                                      user?.accountSettings?.slideshowTimer ??
                                      15,
                                  increment: () {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .incrementAttribute(
                                          user!.id,
                                          "slideshowTimer",
                                        );
                                  },
                                  decrement: () {
                                    ref
                                        .read(
                                          accountSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .decrementAttribute(
                                          user!.id,
                                          "slideshowTimer",
                                        );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(top: 16.0, left: 16.0),
                          child: Text(
                            "Chat API Settings",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Card.outlined(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final shelterSettings = ref
                                  .watch(shelterSettingsViewModelProvider)
                                  .value;
                              if (shelterSettings == null) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "API Token Usage",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Monthly Usage: ${shelterSettings.shelterSettings.tokenCount} / ${shelterSettings.shelterSettings.tokenLimit} tokens",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value:
                                              shelterSettings
                                                  .shelterSettings
                                                  .tokenCount /
                                              shelterSettings
                                                  .shelterSettings
                                                  .tokenLimit,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                shelterSettings
                                                            .shelterSettings
                                                            .tokenCount >
                                                        shelterSettings
                                                                .shelterSettings
                                                                .tokenLimit *
                                                            0.9
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Last Reset: ${shelterSettings.shelterSettings.lastTokenReset != null ? DateTime.parse(shelterSettings.shelterSettings.lastTokenReset.toString()).toLocal().toString().split('.')[0] : 'Never'}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 25.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
