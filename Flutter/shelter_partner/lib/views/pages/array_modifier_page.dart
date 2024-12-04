import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';

class ArrayModifierPage extends ConsumerStatefulWidget {
  final String title;
  final String arrayKey;

  const ArrayModifierPage({
    required this.title,
    required this.arrayKey,
    super.key,
  });

  @override
  _ArrayModifierPageState createState() => _ArrayModifierPageState();
}

class _ArrayModifierPageState extends ConsumerState<ArrayModifierPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelterAsyncValue = ref.watch(shelterSettingsViewModelProvider);

    return shelterAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) {
        final List arrayItems =
            shelter!.shelterSettings.getArray(widget.arrayKey);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
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
                        controller: _itemController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final itemName = _itemController.text;
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .addStringToShelterSettingsArray(
                                    shelter.id, widget.arrayKey, itemName);
                            _itemController.clear();
                          }
                        },
                        child: const Text('Add Item'),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'Existing Items:',
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
                            final item = arrayItems.removeAt(oldIndex);
                            arrayItems.insert(newIndex, item);
                          });
                          ref
                              .read(shelterSettingsViewModelProvider.notifier)
                              .reorderShelterSettingsArray(shelter.id,
                                  widget.arrayKey, arrayItems.cast<String>());
                        },
                        children: [
                          for (int index = 0;
                              index < arrayItems.length;
                              index++)
                            Dismissible(
                              key: ValueKey(arrayItems[index]),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                final removedItem = arrayItems[index];
                                setState(() {
                                  arrayItems.removeAt(index);
                                });
                                ref
                                    .read(shelterSettingsViewModelProvider
                                        .notifier)
                                    .removeStringFromShelterSettingsArray(
                                        shelter.id,
                                        widget.arrayKey,
                                        removedItem);
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: ListTile(
                                title: Text(arrayItems[index]),
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
        );
      },
    );
  }
}
