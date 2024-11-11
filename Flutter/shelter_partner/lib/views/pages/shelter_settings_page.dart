import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text("Shelter Settings"),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    ),
    error: (error, stack) => Scaffold(
      appBar: AppBar(
        title: const Text("Shelter Settings"),
      ),
      body: Center(
        child: Text('Error: $error'),
      ),
    ),
    data: (shelter) {
      // Conditionally update the controller's text
      if (_apiKeyController.text != shelter?.shelterSettings.apiKey) {
        _apiKeyController.text = shelter!.shelterSettings.apiKey;
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text("Shelter Settings"),
        ),
        body: GestureDetector(
          onTap: () {
        _focusNode.unfocus();
          },
          child: SingleChildScrollView(
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
                              context.push('/settings/shelter-settings/scheduled-reports');
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
                              context.push('/settings/shelter-settings/cat-tags');
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
                              context.push('/settings/shelter-settings/dog-tags');
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
                              context.push('/settings/shelter-settings/early-put-back-reasons');
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
                              context.push('/settings/shelter-settings/let-out-types');
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
                              context.push('/settings/shelter-settings/api-keys');
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
                            value: shelter?.shelterSettings.automaticallyPutBackAnimals ?? false,
                            onChanged: (bool newValue) {
                              ref
                                  .read(shelterSettingsViewModelProvider.notifier)
                                  .toggleAttribute(shelter!.id, "automaticallyPutBackAnimals");
                            },
                          ),
                          ),
                          
                          Divider(
                            color: Colors.black.withOpacity(0.1),
                            height: 0,
                            thickness: 1,
                          ),
                          ListTile(title: SwitchToggleView(
                            title: "Ignore Visit When Automatically Put Back",
                            value: shelter?.shelterSettings.ignoreVisitWhenAutomaticallyPutBack ?? false,
                            onChanged: (bool newValue) {
                              ref
                                  .read(shelterSettingsViewModelProvider.notifier)
                                  .toggleAttribute(shelter!.id, "ignoreVisitWhenAutomaticallyPutBack");
                            },
                          ),),
                          Divider(
                            color: Colors.black.withOpacity(0.1),
                            height: 0,
                            thickness: 1,
                          ),
                          ListTile(title: NumberStepperView(
                            title: "Automatic Put Back",
                            label: "hours",
                            value: shelter?.shelterSettings.automaticPutBackHours ?? 0,
                            increment: () {
                              ref
                                  .read(shelterSettingsViewModelProvider.notifier)
                                  .incrementAttribute(shelter!.id, "automaticPutBackHours");
                            },
                            decrement: () {
                              ref
                                  .read(shelterSettingsViewModelProvider.notifier)
                                  .decrementAttribute(shelter!.id, "automaticPutBackHours");
                            },
                          ),)
                          
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
                            labelText: "${shelter?.managementSoftware} API Key",
                            hintText: "${shelter?.managementSoftware} API Key",
                          ),
                          controller: _apiKeyController,
                          focusNode: _focusNode,
                          onChanged: (String value) {
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .modifyShelterSettingString(shelter!.id, "apiKey", value);
                          },
                        ),
                      ),
                    ),
                    ] 
                    // else if (shelter?.managementSoftware == "ASM") ...[
                    //   Card.outlined(
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: TextField(
                    //       decoration: const InputDecoration(
                    //         labelText: "ASM Username",
                    //         hintText: "ASM Username",
                    //       ),
                    //       controller: _apiKeyController,
                    //       focusNode: _focusNode,
                    //       onChanged: (String value) {
                    //         ref
                    //             .read(shelterSettingsViewModelProvider.notifier)
                    //             .modifyShelterSettingString(shelter!.id, "apiKey", value);
                    //       },
                    //     ),
                    //   ),
                    // ),
                    // ],
                    
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      
    }
    );
  }
}
