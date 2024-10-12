import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:uuid/uuid.dart';

class ApiKeysPage extends ConsumerStatefulWidget {
  final String title;
  final String arrayKey;

  const ApiKeysPage({
    required this.title,
    required this.arrayKey,
    super.key,
  });

  @override
  _ApiKeysPageState createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends ConsumerState<ApiKeysPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  List<String> _arrayItems = [];

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
        if (_arrayItems.isEmpty) {
          _arrayItems = shelter!.shelterSettings.getArray(widget.arrayKey);
        }

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
                          labelText: 'Key Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a key name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final itemName = _itemController.text;
                            final newKey = Uuid().v4();
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .addMapToShelterSettingsArray(
                                    shelter!.id,
                                    "apiKeys",
                                    {"name": itemName, "key": newKey});
                            setState(() {
                              _arrayItems.add(itemName);
                            });
                            _itemController.clear();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('API Key Created'),
                                content: Text(
                                    'Your new API key is $newKey. Please copy and store it safely. You won\'t be able to access it after dismissing this alert.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: newKey));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'API key copied to clipboard')),
                                      );
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Copy'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: const Text('Add Key'),
                      ),
                      const SizedBox(height: 20.0),
                      Text("${shelter?.shelterSettings.requestCount}/${shelter?.shelterSettings.requestLimit} requests made in the last 30 days"),
                      const SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  'https://api-222422545919.us-central1.run.app?shelterId=${shelter!.id}&apiKey=YOUR-API-KEY-HERE&species=cats'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard')),
                          );
                        },
                        child: const Text(
                          'Cats Endpoint',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  'https://api-222422545919.us-central1.run.app?shelterId=${shelter!.id}&apiKey=YOUR-API-KEY-HERE&species=dogs'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard')),
                          );
                        },
                        child: const Text(
                          'Dogs Endpoint',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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
                            final item = _arrayItems.removeAt(oldIndex);
                            _arrayItems.insert(newIndex, item);
                          });
                          final List<Map<String, dynamic>> arrayItemsMap =
                              _arrayItems
                                  .map((item) => {
                                        "name": item,
                                        "key": UniqueKey().toString()
                                      })
                                  .toList();
                          ref
                              .read(shelterSettingsViewModelProvider.notifier)
                              .reorderMapArrayInShelterSettings(
                                  shelter!.id, widget.arrayKey, arrayItemsMap);
                        },
                        children: [
                          for (int index = 0;
                              index < _arrayItems.length;
                              index++)
                            Dismissible(
                              key: ValueKey(_arrayItems[index]),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                final removedItem = _arrayItems[index];
                                setState(() {
                                  _arrayItems.removeAt(index);
                                });
                                ref
                                    .read(shelterSettingsViewModelProvider
                                        .notifier)
                                    .removeStringFromShelterSettingsArray(
                                        shelter!.id,
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
                                title: Text(_arrayItems[index]),
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
