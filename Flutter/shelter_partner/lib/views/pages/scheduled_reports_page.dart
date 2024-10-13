import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/scheduled_report.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:uuid/uuid.dart';

class ScheduledReportsPage extends ConsumerStatefulWidget {
  final String title;
  final String arrayKey;

  const ScheduledReportsPage({
    required this.title,
    required this.arrayKey,
    super.key,
  });

  @override
  _ScheduledReportsPageState createState() => _ScheduledReportsPageState();
}

class _ScheduledReportsPageState extends ConsumerState<ScheduledReportsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedType = 'Type 1';
  List<ScheduledReport> _arrayItems = [];

  @override
  void dispose() {
    _itemController.dispose();
    _emailController.dispose();
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
          _arrayItems = shelter!.shelterSettings.scheduledReports;
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
                          labelText: 'Report Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a report title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                        ),
                        items: <String>['Type 1', 'Type 2', 'Type 3']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedType = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final itemName = _itemController.text;
                            final email = _emailController.text;
                            final newID = const Uuid().v4();
                            final newReport = ScheduledReport(
                              title: itemName,
                              id: newID,
                              email: email,
                              type: _selectedType,
                            );
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .addMapToShelterSettingsArray(
                                    shelter!.id, "scheduledReports", newReport.toMap());
                            setState(() {
                              _arrayItems.add(newReport);
                            });
                            _itemController.clear();
                            _emailController.clear();
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
                                  .map((scheduledReport) => scheduledReport.toMap())
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
                                    .removeMapFromShelterSettingsArray(
                                      shelter!.id,
                                      widget.arrayKey,
                                      removedItem.toMap(),
                                    );
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
                                title: Text(_arrayItems[index].title),
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
