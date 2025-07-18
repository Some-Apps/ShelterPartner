import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/repositories/update_volunteer_repository.dart';
import 'package:shelter_partner/view_models/add_log_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:uuid/uuid.dart';

class AddLogView extends ConsumerStatefulWidget {
  final Animal animal;

  const AddLogView({super.key, required this.animal});

  @override
  AddLogViewState createState() => AddLogViewState();
}

class AddLogViewState extends ConsumerState<AddLogView> {
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _selectedType;
  String? _selectedEarlyReason;

  DateTime _startTime = DateTime.now().subtract(const Duration(minutes: 30));
  DateTime _endTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  void _updateControllers() {
    _startTimeController.text = _formatTime(_startTime);
    _endTimeController.text = _formatTime(_endTime);
    final duration = _endTime.difference(_startTime).inMinutes;
    _durationController.text = duration.toString();
  }

  void _updateTimeControllers() {
    _startTimeController.text = _formatTime(_startTime);
    _endTimeController.text = _formatTime(_endTime);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null) {
      final now = DateTime.now();
      final selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
        _updateControllers();
      });
    }
  }

  void _onDurationChanged(String value) {
    final minutes = int.tryParse(value);
    if (minutes != null && minutes > 0) {
      setState(() {
        _startTime = _endTime.subtract(Duration(minutes: minutes));
        _updateTimeControllers();
      });
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetails = ref.read(appUserProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final logger = ref.watch(loggerServiceProvider);

    return AlertDialog(
      title: Text(widget.animal.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: [
                if (_selectedType != null) ...[
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                ],
                ...?shelterSettings.value?.shelterSettings.letOutTypes.map((
                  String type,
                ) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Select log type...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedEarlyReason,
              items: [
                if (_selectedEarlyReason != null) ...[
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                ],
                ...?shelterSettings.value?.shelterSettings.earlyPutBackReasons
                    .map((String reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedEarlyReason = newValue;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Select early reason...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _startTimeController,
              readOnly: true,
              onTap: () => _selectTime(context, true),
              decoration: const InputDecoration(
                labelText: 'Start time',
                hintText: 'Select start time...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endTimeController,
              readOnly: true,
              onTap: () => _selectTime(context, false),
              decoration: const InputDecoration(
                labelText: 'End time',
                hintText: 'Select end time...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              onChanged: _onDurationChanged,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'Duration in minutes...',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedType != null && _selectedType!.isNotEmpty)
              ? () async {
                  Log log = Log(
                    id: const Uuid().v4().toString(),
                    type: _selectedType ?? '',
                    author: userDetails!.firstName,
                    authorID: userDetails.id,
                    startTime: Timestamp.fromDate(_startTime),
                    endTime: Timestamp.fromDate(_endTime),
                    earlyReason: _selectedEarlyReason,
                  );

                  await ref
                      .read(addLogViewModelProvider(widget.animal).notifier)
                      .addLogToAnimal(widget.animal, log)
                      .then((_) {
                        logger.info('Log added');
                        if (mounted) {
                          logger.info('Updating last activity');
                          ref
                              .read(updateVolunteerRepositoryProvider)
                              .modifyVolunteerLastActivity(
                                userDetails.id,
                                Timestamp.now(),
                              );
                          logger.info('Last activity updated');
                        }
                      });
                  if (!context.mounted) return;
                  Navigator.of(context).pop(log);
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
