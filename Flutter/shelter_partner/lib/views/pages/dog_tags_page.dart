import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';

class DogTagsPage extends ConsumerStatefulWidget {
  const DogTagsPage({super.key});

  @override
  _DogTagsPageState createState() => _DogTagsPageState();
}

class _DogTagsPageState extends ConsumerState<DogTagsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tagNameController = TextEditingController();

  @override
  void dispose() {
    _tagNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterSettingsViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text("Dog Tags"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text("Dog Tags"),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        appBar: AppBar(
          title: const Text("Dog Tags"),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _tagNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tag Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a tag name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // Add your tag addition logic here
                          final tagName = _tagNameController.text;
                          print(_tagNameController.text);
                          ref.read(shelterSettingsViewModelProvider.notifier).addStringToShelterSettingsArray(shelter!.id, "dogTags", tagName);
                          _tagNameController.clear(); // Clear the text field
                        }
                      },
                      child: const Text('Add Tag'),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Existing Tags:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10.0),
                    ReorderableListView(
                      shrinkWrap: true,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final tag = shelter!.shelterSettings.dogTags.removeAt(oldIndex);
                          shelter.shelterSettings.dogTags.insert(newIndex, tag);
                        });
                        ref.read(shelterSettingsViewModelProvider.notifier).reorderShelterSettingsArray(shelter.id, "dogTags", shelter.shelterSettings.dogTags);
                      },
                      children: [
                        for (int index = 0; index < shelter!.shelterSettings.dogTags.length; index++)
                          Dismissible(
                            key: ValueKey(shelter.shelterSettings.dogTags[index]),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              setState(() {
                                shelter.shelterSettings.dogTags.removeAt(index);
                              });
                              ref.read(shelterSettingsViewModelProvider.notifier).removeStringFromShelterSettingsArray(shelter.id, "dogTags", shelter.shelterSettings.dogTags[index]);
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              title: Text(shelter.shelterSettings.dogTags[index]),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
