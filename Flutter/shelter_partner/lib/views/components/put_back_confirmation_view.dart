import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/view_models/put_back_confirmation_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';
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
  String? _selectedEarlyReason;
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateConfirmButtonState();
  }
  void _updateConfirmButtonState() {
    setState(() {
      _isConfirmEnabled = ((_selectedEarlyReason != null && _selectedEarlyReason!.isNotEmpty) || ref.read(deviceSettingsViewModelProvider).value?.deviceSettings.requireEarlyPutBackReason == false 
      || Timestamp.now().toDate().difference(widget.animal.logs.last.startTime.toDate()).inMinutes >= ref.read(deviceSettingsViewModelProvider).value!.deviceSettings.minimumLogMinutes);
    });
  }

  void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thank You'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              
              Text('Thank you for spending time with ${widget.animal.name}!'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Add your addNote functionality here
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddNoteView(animal: widget.animal);
                  },
                );
              },
              child: const Text('Add Note'),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  final deviceSettings = ref.watch(deviceSettingsViewModelProvider);
  final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
  final takeOutViewModel = ref.read(putBackConfirmationViewModelProvider(widget.animal).notifier);

  if (deviceSettings.value?.deviceSettings.requireEarlyPutBackReason == false) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      takeOutViewModel.putBackAnimal(
        widget.animal,
        Log(
          id: const Uuid().v4().toString(),
          type: '',
          author: _nameController.text,
          earlyReason: '',
          startTime: Timestamp.now(),
          endTime: Timestamp.now(),
        ),
      );
      _showThankYouDialog(context);
    });
    return const SizedBox.shrink();
  }

  if (shelterSettings.value?.shelterSettings.earlyPutBackReasons == null) {
    return const CircularProgressIndicator(); // Show a loading indicator while the data loads
  }

  return AlertDialog(
    title: const Text('Confirm Action'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Do you want to put ${widget.animal.name} back into ${widget.animal.sex == 'male' ? 'his' : 'her'} kennel?'),
        const SizedBox(height: 20),
        if (widget.animal.putBackAlert.isNotEmpty) 
        RichText(
              text: TextSpan(
              children: [
                const TextSpan(
                text: 'Alert: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                TextSpan(
                text: widget.animal.putBackAlert,
                style: const TextStyle(color: Colors.red),
                ),
              ],
              ),
            ),
        if (deviceSettings.value?.deviceSettings.requireEarlyPutBackReason == true &&
            shelterSettings.value?.shelterSettings.earlyPutBackReasons.isNotEmpty == true &&
            widget.animal.logs.isNotEmpty &&
            Timestamp.now().toDate().difference(widget.animal.logs.last.startTime.toDate()).inMinutes < deviceSettings.value!.deviceSettings.minimumLogMinutes)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Early Put Back Reason: '),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedEarlyReason,
                hint: const Text('Select reason'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedEarlyReason = newValue;
                    _updateConfirmButtonState();
                  });
                },
                items: shelterSettings.value!.shelterSettings.earlyPutBackReasons
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
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
                    type: _selectedEarlyReason ?? '',
                    author: _nameController.text,
                    earlyReason: '',
                    startTime: Timestamp.now(),
                    endTime: Timestamp.now(),
                  ),
                );
                Navigator.of(context).pop(true); // User confirmed
                _showThankYouDialog(context);
              }
            : null,
        child: const Text('Confirm'),
      ),
    ],
  );
}

}
