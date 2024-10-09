import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';

class CatTagsPage extends ConsumerStatefulWidget {
  const CatTagsPage({super.key});

  @override
  _CatTagsPageState createState() => _CatTagsPageState();
}

class _CatTagsPageState extends ConsumerState<CatTagsPage> {
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
          title: const Text("Cat Tags"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text("Cat Tags"),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) => Scaffold(
        appBar: AppBar(
          title: const Text("Cat Tags"),
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
                          ref
                              .read(shelterSettingsViewModelProvider.notifier)
                              .addStringToShelterSettingsArray(
                                  shelter!.id, "catTags", tagName);
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
                          final tag = shelter!.shelterSettings.catTags
                              .removeAt(oldIndex);
                          shelter.shelterSettings.catTags.insert(newIndex, tag);
                        });
                        ref
                            .read(shelterSettingsViewModelProvider.notifier)
                            .reorderShelterSettingsArray(shelter.id, "catTags",
                                shelter.shelterSettings.catTags);
                      },
                      children: [
                        for (int index = 0;
                            index < shelter!.shelterSettings.catTags.length;
                            index++)
                          Dismissible(
                            key: ValueKey(
                                shelter.shelterSettings.catTags[index]),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              final removedTag = shelter
                                      .shelterSettings.catTags[
                                  index]; // Store the tag before removing it
                              setState(() {
                                shelter.shelterSettings.catTags
                                    .removeAt(index); // Remove the tag
                              });
                              ref
                                  .read(
                                      shelterSettingsViewModelProvider.notifier)
                                  .removeStringFromShelterSettingsArray(
                                      shelter.id,
                                      "catTags",
                                      removedTag); // Pass the stored tag to be removed from Firestore
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              title:
                                  Text(shelter.shelterSettings.catTags[index]),
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
