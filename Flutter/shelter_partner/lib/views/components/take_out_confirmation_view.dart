import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/view_models/take_out_confirmation_view_model.dart';
import 'package:uuid/uuid.dart';

class TakeOutConfirmationView extends ConsumerStatefulWidget {
  final Animal animal;

  const TakeOutConfirmationView({
    super.key,
    required this.animal,
  });

  @override
  _TakeOutConfirmationViewState createState() => _TakeOutConfirmationViewState();
}

class _TakeOutConfirmationViewState extends ConsumerState<TakeOutConfirmationView> {
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
      final deviceSettings = ref.read(deviceSettingsViewModelProvider);
      final requireLetOutType = deviceSettings.value?.deviceSettings?.requireLetOutType ?? false;
      final requireName = deviceSettings.value?.deviceSettings?.requireName ?? false;

      _isConfirmEnabled = (!requireLetOutType || (_selectedLetOutType != null && _selectedLetOutType!.isNotEmpty)) &&
              (!requireName || _nameController.text.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSettings = ref.read(deviceSettingsViewModelProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final userDetails = ref.read(appUserProvider);
final takeOutViewModel = ref.read(takeOutConfirmationViewModelProvider(widget.animal).notifier);


    return AlertDialog(
      title: const Text('Confirm Action'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Do you want to take ${widget.animal.name} out of ${widget.animal.sex == 'male' ? 'his' : 'her'} kennel?',
          ),
          const SizedBox(height: 20),
            if (widget.animal.takeOutAlert.isNotEmpty)
            RichText(
              text: TextSpan(
              children: [
                const TextSpan(
                text: 'Alert: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                TextSpan(
                text: widget.animal.takeOutAlert,
                style: const TextStyle(color: Colors.red),
                ),
              ],
              ),
            ),
          if (deviceSettings.value?.deviceSettings?.requireLetOutType == true &&
              shelterSettings.value?.shelterSettings.letOutTypes.isNotEmpty == true)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Type of Let Out'),
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
            
          if (deviceSettings.value?.deviceSettings?.requireName == true &&
              (userDetails?.firstName != null || deviceSettings.value?.deviceSettings?.mode != "Admin"))
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

                  takeOutViewModel.takeOutAnimal(
                  widget.animal,
                  Log(
                    id: const Uuid().v4().toString(),
                    type: _selectedLetOutType ?? '',
                    author: _nameController.text,
                    earlyReason: '',
                    startTime: Timestamp.now(),
                    endTime: widget.animal.logs.last.endTime,
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
