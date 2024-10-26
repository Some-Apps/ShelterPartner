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
  final List<Animal> animals; // Accepts a list of animals

  const PutBackConfirmationView({
    super.key,
    required this.animals,
  });

  @override
  _PutBackConfirmationViewState createState() =>
      _PutBackConfirmationViewState();
}

class _PutBackConfirmationViewState
    extends ConsumerState<PutBackConfirmationView> {
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
    final deviceSettings = ref.read(deviceSettingsViewModelProvider);
    setState(() {
      _isConfirmEnabled =
          ((_selectedEarlyReason != null && _selectedEarlyReason!.isNotEmpty) ||
              deviceSettings.value?.deviceSettings?.requireEarlyPutBackReason ==
                  false ||
              widget.animals.every((animal) =>
                  Timestamp.now()
                      .toDate()
                      .difference(animal.logs.last.startTime.toDate())
                      .inMinutes >=
                  deviceSettings.value!.deviceSettings!.minimumLogMinutes));
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
              Text(
              widget.animals.length == 1
                ? 'Thank you for spending time with ${widget.animals.first.name}!'
                : 'Thank you for spending time with the selected animals!',
              ),
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
                Navigator.of(context).pop();
                for (var animal in widget.animals) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AddNoteView(animal: animal);
                    },
                  );
                }
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
    final putBackViewModel = ref.read(
        putBackConfirmationViewModelProvider(widget.animals.first).notifier);

    if (deviceSettings.value?.deviceSettings?.requireEarlyPutBackReason ==
        false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (var animal in widget.animals) {
          putBackViewModel.putBackAnimal(
            animal,
            Log(
              id: const Uuid().v4().toString(),
              type: '',
              author: _nameController.text,
              earlyReason: '',
              startTime: Timestamp.now(),
              endTime: Timestamp.now(),
            ),
          );
        }
        _showThankYouDialog(context);
      });
      return const SizedBox.shrink();
    }

    if (shelterSettings.value?.shelterSettings.earlyPutBackReasons == null) {
      return const CircularProgressIndicator();
    }

    return AlertDialog(
      title: Center(
        child: Text(
          widget.animals.length == 1
              ? 'Confirm Action for ${widget.animals.first.name}'
              : 'Confirm Action for ${widget.animals.length} animals',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Text(
            widget.animals.length == 1
              ? 'Do you want to put ${widget.animals.first.name} back into their kennel?'
              : 'Do you want to put the selected animals back into their kennels?',
            ),
          const SizedBox(height: 20),
          for (var animal in widget.animals)
            if (animal.putBackAlert.isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Alert for ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: animal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const TextSpan(
                      text: ': ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: animal.putBackAlert,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
          if (deviceSettings
                      .value?.deviceSettings?.requireEarlyPutBackReason ==
                  true &&
              shelterSettings
                      .value?.shelterSettings.earlyPutBackReasons.isNotEmpty ==
                  true &&
              widget.animals.any((animal) =>
                  Timestamp.now()
                      .toDate()
                      .difference(animal.logs.last.startTime.toDate())
                      .inMinutes <
                  deviceSettings.value!.deviceSettings!.minimumLogMinutes))
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
                  items: shelterSettings
                      .value!.shelterSettings.earlyPutBackReasons
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
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isConfirmEnabled
              ? () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );

                  for (var animal in widget.animals) {
                    await putBackViewModel.putBackAnimal(
                      animal,
                      Log(
                        id: const Uuid().v4().toString(),
                        type: _selectedEarlyReason ?? '',
                        author: _nameController.text,
                        earlyReason: '',
                        startTime: Timestamp.now(),
                        endTime: Timestamp.now(),
                      ),
                    );
                  }

                  Navigator.of(context).pop(); // Close the progress indicator
                  Navigator.of(context).pop(true);
                  _showThankYouDialog(context);
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
