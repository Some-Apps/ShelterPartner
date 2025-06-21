import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/views/components/number_stepper_view.dart';
import 'package:shelter_partner/views/components/switch_toggle_view.dart';

class ShelterSettingsPage extends ConsumerStatefulWidget {
  const ShelterSettingsPage({super.key});

  @override
  _ShelterSettingsPageState createState() => _ShelterSettingsPageState();
}

class _ShelterSettingsPageState extends ConsumerState<ShelterSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterSettingsViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text("Shelter Settings")),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text("Shelter Settings")),
        body: Center(child: Text('Error: $error')),
      ),
      data: (shelter) {
        // Conditionally update the controller's text
        if (_apiKeyController.text != shelter?.shelterSettings.apiKey) {
          _apiKeyController.text = shelter!.shelterSettings.apiKey;
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Shelter Settings")),
          body: GestureDetector(
            onTap: () {
              _focusNode.unfocus();
            },
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card.outlined(
                            child: ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                ListTile(
                                  title: const Text("Scheduled Reports"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push(
                                      '/settings/shelter-settings/scheduled-reports',
                                    );
                                  },
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                                ListTile(
                                  title: const Text("Cat Tags"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push(
                                      '/settings/shelter-settings/cat-tags',
                                    );
                                  },
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                                ListTile(
                                  title: const Text("Dog Tags"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push(
                                      '/settings/shelter-settings/dog-tags',
                                    );
                                  },
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                                ListTile(
                                  title: const Text("Early Put Back Reasons"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push(
                                      '/settings/shelter-settings/early-put-back-reasons',
                                    );
                                  },
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                                ListTile(
                                  title: const Text("Let Out Types"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push(
                                      '/settings/shelter-settings/let-out-types',
                                    );
                                  },
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                                ListTile(
                                  title: const Text("API Keys"),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.push(
                                      '/settings/shelter-settings/api-keys',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          Card.outlined(
                            child: ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                ListTile(
                                  title: SwitchToggleView(
                                    title: "Automatically Put Back Animals",
                                    value:
                                        shelter
                                            ?.shelterSettings
                                            .automaticallyPutBackAnimals ??
                                        false,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "automaticallyPutBackAnimals",
                                          );
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
                                    title:
                                        "Ignore Visit When Automatically Put Back",
                                    value:
                                        shelter
                                            ?.shelterSettings
                                            .ignoreVisitWhenAutomaticallyPutBack ??
                                        false,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "ignoreVisitWhenAutomaticallyPutBack",
                                          );
                                    },
                                  ),
                                ),
                                Divider(
                                  color: Colors.black.withOpacity(0.1),
                                  height: 0,
                                  thickness: 1,
                                ),
                                ListTile(
                                  title: NumberStepperView(
                                    title: "Automatic Put Back",
                                    label: "hours",
                                    minValue: 1,
                                    maxValue: 96,
                                    value:
                                        shelter
                                            ?.shelterSettings
                                            .automaticPutBackHours ??
                                        0,
                                    increment: () {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .incrementAttribute(
                                            shelter!.id,
                                            "automaticPutBackHours",
                                          );
                                    },
                                    decrement: () {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .decrementAttribute(
                                            shelter!.id,
                                            "automaticPutBackHours",
                                          );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25.0),
                          if (shelter?.managementSoftware == "ShelterLuv") ...[
                            Card.outlined(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText:
                                        "${shelter?.managementSoftware} API Key",
                                    hintText:
                                        "${shelter?.managementSoftware} API Key",
                                  ),
                                  controller: _apiKeyController,
                                  focusNode: _focusNode,
                                  onChanged: (String value) {
                                    ref
                                        .read(
                                          shelterSettingsViewModelProvider
                                              .notifier,
                                        )
                                        .modifyShelterSettingString(
                                          shelter!.id,
                                          "apiKey",
                                          value,
                                        );
                                  },
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 25),
                          Card.outlined(
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    "Sync with ${shelter?.managementSoftware} scheduled report",
                                  ),
                                  subtitle: Text.rich(
                                    TextSpan(
                                      text:
                                          "If you need the app to use more information that it has access to with the API alone, you can schedule a daily scheduled report. Make sure to schedule it for 5AM CST. The subject line needs to be ",
                                      children: [
                                        TextSpan(
                                          text: shelter
                                              ?.shelterSettings
                                              .shortUUID,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const ListTile(
                                  title: Text(
                                    "How to set up the scheduled report",
                                  ),
                                  subtitle: Text(
                                    "Only send information on animals. Check all available fields and set the report to send daily at 5AM CST to reports@shelterpartner.org. Give it 24 hours and Shelter Partner will automatically start using the new information. This is meant to be used in conjunction with the API, not as a replacement.",
                                  ),
                                ),
                                ListTile(
                                  title: const Text(
                                    "Copy email subject to clipboard",
                                  ),
                                  trailing: const Icon(Icons.copy),
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text:
                                            shelter!.shelterSettings.shortUUID,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Email subject copied to clipboard",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Text(
                              "Visitor Chat Privacy Settings",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Card.outlined(
                            child: ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                ListTile(
                                  title: SwitchToggleView(
                                    title: "Show Species",
                                    value:
                                        shelter?.shelterSettings.showSpecies ??
                                        true,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "showSpecies",
                                          );
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
                                    title: "Show Breed",
                                    value:
                                        shelter?.shelterSettings.showBreed ??
                                        true,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "showBreed",
                                          );
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
                                    title: "Show Description",
                                    value:
                                        shelter
                                            ?.shelterSettings
                                            .showDescription ??
                                        true,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "showDescription",
                                          );
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
                                    title: "Show Location",
                                    value:
                                        shelter?.shelterSettings.showLocation ??
                                        true,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "showLocation",
                                          );
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
                                    title: "Show Medical Info",
                                    value:
                                        shelter
                                            ?.shelterSettings
                                            .showMedicalInfo ??
                                        false,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "showMedicalInfo",
                                          );
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
                                    title: "Show Behavior Info",
                                    value:
                                        shelter
                                            ?.shelterSettings
                                            .showBehaviorInfo ??
                                        true,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "showBehaviorInfo",
                                          );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Text(
                              "ShelterLuv Integration Settings",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Card.outlined(
                            child: ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                ListTile(
                                  title: SwitchToggleView(
                                    title:
                                        "Only Include Primary Photo From ShelterLuv",
                                    value:
                                        shelter
                                            ?.shelterSettings
                                            .onlyIncludePrimaryPhotoFromShelterLuv ??
                                        true,
                                    onChanged: (bool newValue) {
                                      ref
                                          .read(
                                            shelterSettingsViewModelProvider
                                                .notifier,
                                          )
                                          .toggleAttribute(
                                            shelter!.id,
                                            "onlyIncludePrimaryPhotoFromShelterLuv",
                                          );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
