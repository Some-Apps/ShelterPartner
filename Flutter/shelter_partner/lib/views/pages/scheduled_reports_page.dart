import 'package:flutter/material.dart';
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
  String _selectedFrequency = 'Weekly';
  String _selectedDayOfWeek = 'Monday';
  String _selectedDayOfMonth = '1';
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
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text('Error: $error')),
      ),
      data: (shelter) {
        if (_arrayItems.isEmpty) {
          _arrayItems = shelter!.shelterSettings.scheduledReports;
          _arrayItems.sort((a, b) => a.title.compareTo(b.title));
        }

        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
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
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      DropdownButtonFormField<String>(
                        value: _selectedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                        ),
                        items: <String>['Monthly', 'Weekly', 'Daily'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFrequency = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 10.0),
                      if (_selectedFrequency == 'Weekly')
                        DropdownButtonFormField<String>(
                          value: _selectedDayOfWeek,
                          decoration: const InputDecoration(
                            labelText: 'Day of the Week',
                          ),
                          items:
                              <String>[
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedDayOfWeek = newValue!;
                            });
                          },
                        ),
                      if (_selectedFrequency == 'Monthly')
                        DropdownButtonFormField<String>(
                          value: _selectedDayOfMonth,
                          decoration: const InputDecoration(
                            labelText: 'Day of the Month',
                          ),
                          items:
                              List<String>.generate(
                                31,
                                (index) => '${index + 1}',
                              ).map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedDayOfMonth = newValue!;
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
                              frequency: _selectedFrequency,
                              dayOfWeek: _selectedFrequency == 'Weekly'
                                  ? _selectedDayOfWeek
                                  : '',
                              dayOfMonth: _selectedFrequency == 'Monthly'
                                  ? int.parse(_selectedDayOfMonth)
                                  : 0,
                            );
                            ref
                                .read(shelterSettingsViewModelProvider.notifier)
                                .addMapToShelterSettingsArray(
                                  shelter!.id,
                                  "scheduledReports",
                                  newReport.toMap(),
                                );
                            setState(() {
                              _arrayItems.add(newReport);
                              _arrayItems.sort(
                                (a, b) => a.title.compareTo(b.title),
                              );
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
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _arrayItems.length,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: ValueKey(_arrayItems[index]),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) async {
                              final removedItem = _arrayItems[index];
                              setState(() {
                                _arrayItems.removeAt(index);
                              });
                              ref
                                  .read(
                                    shelterSettingsViewModelProvider.notifier,
                                  )
                                  .removeMapFromShelterSettingsArray(
                                    shelter!.id,
                                    widget.arrayKey,
                                    removedItem.toMap(),
                                  );
                              if (_arrayItems.isEmpty) {
                                // ignore: unused_result
                                ref.refresh(shelterSettingsViewModelProvider);
                              }
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              title: Text(_arrayItems[index].title),
                              subtitle: Text(
                                '${_arrayItems[index].email}\n'
                                '${_arrayItems[index].frequency == 'Daily'
                                    ? 'Daily'
                                    : _arrayItems[index].frequency == 'Weekly'
                                    ? _arrayItems[index].dayOfWeek
                                    : 'Every ${_arrayItems[index].dayOfMonth}'}',
                              ),
                            ),
                          );
                        },
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
