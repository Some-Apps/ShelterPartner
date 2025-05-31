import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/repositories/update_volunteer_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/view_models/take_out_confirmation_view_model.dart';
import 'package:uuid/uuid.dart';

class TakeOutConfirmationView extends ConsumerStatefulWidget {
  final List<Animal> animals; // Accepts a list of animals

  const TakeOutConfirmationView({
    super.key,
    required this.animals,
  });

  @override
  TakeOutConfirmationViewState createState() => TakeOutConfirmationViewState();
}

class TakeOutConfirmationViewState
    extends ConsumerState<TakeOutConfirmationView> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedLetOutType;
  bool _isConfirmEnabled = false;

  @override
  void initState() {
    super.initState();
    final userDetails = ref.read(appUserProvider);
    _nameController.text = userDetails?.firstName ?? '';
    _nameController.addListener(_updateConfirmButtonState);
    _updateConfirmButtonState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateConfirmButtonState() {
    setState(() {
      final accountSettings = ref.read(accountSettingsViewModelProvider);
      final shelterSettings = ref.read(shelterSettingsViewModelProvider);
      final userDetails = ref.read(appUserProvider);
      final bool requireLetOutType = userDetails?.type == "admin"
          ? (accountSettings.value?.accountSettings?.requireLetOutType ?? false)
          : (shelterSettings.value?.volunteerSettings.requireLetOutType ??
              false);
      final bool requireName = userDetails?.type == "admin"
          ? (accountSettings.value?.accountSettings?.requireName ?? false)
          : (shelterSettings.value?.volunteerSettings.requireName ?? false);

      _isConfirmEnabled = (!requireLetOutType ||
                  (_selectedLetOutType != null &&
                      _selectedLetOutType!.isNotEmpty)) &&
              (!requireName || _nameController.text.isNotEmpty) ||
          (!requireLetOutType && !requireName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountSettings = ref.read(accountSettingsViewModelProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final userDetails = ref.read(appUserProvider);
    final bool requireLetOutTypeFlag = userDetails?.type == "admin"
        ? (accountSettings.value?.accountSettings?.requireLetOutType ?? false)
        : (shelterSettings.value?.volunteerSettings.requireLetOutType ?? false);
    final bool requireNameFlag = userDetails?.type == "admin"
        ? (accountSettings.value?.accountSettings?.requireName ?? false)
        : (shelterSettings.value?.volunteerSettings.requireName ?? false);

    final takeOutViewModel = ref.read(
        takeOutConfirmationViewModelProvider(widget.animals.first).notifier);

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
                ? 'Do you want to take out ${widget.animals.first.name}?'
                : 'Do you want to take out the selected animals?',
          ),
          const SizedBox(height: 20),
          if (widget.animals.any((animal) => animal.takeOutAlert.isNotEmpty))
            Column(
              children: widget.animals
                  .where((animal) => animal.takeOutAlert.isNotEmpty)
                  .map((animal) => RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Alert for ${animal.name}: ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            TextSpan(
                              text: animal.takeOutAlert,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          if (requireLetOutTypeFlag &&
              shelterSettings.value?.shelterSettings.letOutTypes.isNotEmpty ==
                  true)
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
          if (requireNameFlag)
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
              ? () async {
                  setState(() {
                    _isConfirmEnabled =
                        false; // Disable the button to prevent multiple taps
                  });

                  final currentContext = context;

                  showDialog(
                    context: currentContext,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );

                  // Apply take-out action for each animal in the list
                  for (final animal in widget.animals) {
                    await takeOutViewModel
                        .takeOutAnimal(
                      animal,
                      Log(
                        id: const Uuid().v4().toString(),
                        type: _selectedLetOutType ?? '',
                        author: _nameController.text,
                        authorID: userDetails!.id,
                        earlyReason: '',
                        startTime: Timestamp.now(),
                        endTime: animal.logs.last.endTime,
                      ),
                    )
                        .then((_) {
                      if (mounted) {
                        ref
                            .read(updateVolunteerRepositoryProvider)
                            .modifyVolunteerLastActivity(
                                userDetails.id, Timestamp.now());
                      }
                    });
                  }

                  if (mounted) {
                    Navigator.of(currentContext)
                        .pop(); // Close the loading indicator
                    Navigator.of(currentContext).pop(true); // User confirmed
                  }
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
