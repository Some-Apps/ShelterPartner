import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:uuid/uuid.dart';

class ScheduledReportsPage extends ConsumerStatefulWidget {

  const ScheduledReportsPage({
    super.key,
  });

  @override
  _ScheduledReportsPageState createState() => _ScheduledReportsPageState();
}

class _ScheduledReportsPageState extends ConsumerState<ScheduledReportsPage> {
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
          title: Text("Scheduled Reports"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: Text("Scheduled Reports"),
        ),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
      data: (shelter) {

        return Scaffold(
          appBar: AppBar(
            title: Text("Scheduled Reports"),
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
                          labelText: 'Report Title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a report title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final itemName = _itemController.text;
                            final id = const Uuid().v4();
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .addMapToShelterSettingsArray(
                                    shelter!.id,
                                    "scheduledReports",
                                    {"title": itemName, "id": id});
                            setState(() {
                              _arrayItems.add(itemName);
                            });
                            _itemController.clear();
                            
                          }
                        },
                        child: const Text('Add Report'),
                      ),
                     
                      const SizedBox(height: 20.0),
                      Text(
                        'Existing Reports:',
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
                                        "title": item,
                                        "id": UniqueKey().toString()
                                      })
                                  .toList();
                          ref
                              .read(shelterSettingsViewModelProvider.notifier)
                              .reorderMapArrayInShelterSettings(
                                  shelter!.id, "scheduledReports", arrayItemsMap);
                        },
                        children: [
                          // for (int index = 0;
                          //     index < _arrayItems.length;
                          //     index++)
                          //   Dismissible(
                          //     key: ValueKey(_arrayItems[index]),
                          //     direction: DismissDirection.endToStart,
                          //     onDismissed: (direction) {
                          //       final removedItemTitle = _arrayItems[index];
                          //       setState(() {
                          //         _arrayItems.removeAt(index);
                          //       });
                          //       final removedItem = {
                          //         "title": removedItemTitle,
                          //         "id": UniqueKey().toString()
                          //       };
                          //       ref
                          //           .read(shelterSettingsViewModelProvider
                          //               .notifier)
                          //           .removeMapFromShelterSettingsArrayById(
                          //               shelter!.id,
                          //               "scheduledReports",
                          //               removedItem['id']!);
                          //     },
                          //     background: Container(
                          //       color: Colors.red,
                          //       alignment: Alignment.centerRight,
                          //       padding: const EdgeInsets.symmetric(
                          //           horizontal: 20.0),
                          //       child: const Icon(
                          //         Icons.delete,
                          //         color: Colors.white,
                          //       ),
                          //     ),
                          //     child: ListTile(
                          //       title: Text(_arrayItems[index]),
                          //     ),
                          //   ),
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
