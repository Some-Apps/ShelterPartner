import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:shelter_partner/views/components/navigation_button_view.dart';

class ShelterSettingsPage extends ConsumerStatefulWidget {
  const ShelterSettingsPage({super.key});

  @override
  _ShelterSettingsPageState createState() => _ShelterSettingsPageState();
}

class _ShelterSettingsPageState extends ConsumerState<ShelterSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(volunteersViewModelProvider);

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
      data: (shelter) => Scaffold(
        appBar: AppBar(
          title: const Text("Shelter Settings"),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(children: [
                        NavigationButton(
                            title: "Scheduled Reports",
                            route:
                                '/settings/shelter-settings/scheduled-reports'),
                        NavigationButton(
                            title: "Cat Tags",
                            route: '/settings/shelter-settings/cat-tags'),
                        NavigationButton(
                            title: "Dog Tags",
                            route: '/settings/shelter-settings/dog-tags'),
                        NavigationButton(
                            title: "Early Put Back Reasons",
                            route:
                                '/settings/shelter-settings/early-put-back-reasons'),
                        NavigationButton(
                            title: "Let Out Types",
                            route: '/settings/shelter-settings/let-out-types'),
                        NavigationButton(
                            title: "API Keys",
                            route: '/settings/shelter-settings/api-keys'),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
