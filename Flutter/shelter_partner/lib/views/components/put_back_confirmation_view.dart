import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/view_models/put_back_confirmation_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:uuid/uuid.dart';

class PutBackConfirmationView extends ConsumerStatefulWidget {
  final Animal animal;

  const PutBackConfirmationView({
    super.key,
    required this.animal,
  });

  @override
  _PutBackConfirmationViewState createState() => _PutBackConfirmationViewState();
}

class _PutBackConfirmationViewState extends ConsumerState<PutBackConfirmationView> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedLetOutType;
  bool _isConfirmEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateConfirmButtonState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateConfirmButtonState() {
    setState(() {
      _isConfirmEnabled = (_selectedLetOutType != null && _selectedLetOutType!.isNotEmpty) &&
                          (_nameController.text.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSettings = ref.read(deviceSettingsViewModelProvider);
    final shelterSettings = ref.read(shelterSettingsViewModelProvider);
    final userDetails = ref.read(appUserProvider);
final takeOutViewModel = ref.read(putBackConfirmationViewModelProvider(widget.animal).notifier);


    return AlertDialog(
      title: const Text('Confirm Action'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Do you want to take ${widget.animal.name} out of the kennel?',
          ),
          const SizedBox(height: 20),
          if (widget.animal.alert.isNotEmpty)
            Text(widget.animal.alert),
          if (deviceSettings.value?.deviceSettings.requireLetOutType == true &&
              shelterSettings.value?.shelterSettings.letOutTypes.isNotEmpty == true)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Let Out Type: '),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedLetOutType,
                  hint: const Text('Select type'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLetOutType = newValue;
                      _updateConfirmButtonState();
                    });
                  },
                  items: shelterSettings.value!.shelterSettings.letOutTypes
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          if (deviceSettings.value?.deviceSettings.requireName == true &&
              (userDetails?.firstName != null || deviceSettings.value?.deviceSettings.adminMode == true))
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Volunteer Name',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // User canceled
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isConfirmEnabled
              ? () {

                  takeOutViewModel.putBackAnimal(
                  widget.animal,
                  Log(
                    id: const Uuid().v4().toString(),
                    type: _selectedLetOutType ?? '',
                    author: _nameController.text,
                    earlyReason: '',
                    startTime: Timestamp.now(),
                    endTime: Timestamp.now(),
                  ),
                );
                  Navigator.of(context).pop(true); // User confirmed
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
