import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/put_back_confirmation_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PutBackConfirmationView extends ConsumerStatefulWidget {
  final List<Animal> animals; // Accepts a list of animals

  const PutBackConfirmationView({super.key, required this.animals});

  @override
  PutBackConfirmationViewState createState() => PutBackConfirmationViewState();
}

class PutBackConfirmationViewState
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
    final accountSettings = ref.read(accountSettingsViewModelProvider);
    setState(() {
      _isConfirmEnabled =
          ((_selectedEarlyReason != null && _selectedEarlyReason!.isNotEmpty) ||
          accountSettings.value?.accountSettings?.requireEarlyPutBackReason ==
              false ||
          widget.animals.every(
            (animal) =>
                Timestamp.now()
                    .toDate()
                    .difference(animal.logs.last.startTime.toDate())
                    .inMinutes >=
                accountSettings.value!.accountSettings!.minimumLogMinutes,
          ));
    });
  }

  void _showThankYouDialog(BuildContext context) {
    final accountSettings = ref.watch(accountSettingsViewModelProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final appUser = ref.watch(appUserProvider);
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
            if ((appUser?.type == 'admin' &&
                    accountSettings.value?.accountSettings?.showCustomForm ==
                        true) ||
                (appUser?.type == 'volunteer' &&
                    shelterSettings.value?.volunteerSettings.showCustomForm ==
                        true))
              TextButton(
                onPressed: () async {
                  // Custom Form button pressed
                  String url =
                      accountSettings.value?.accountSettings?.customFormURL ??
                      '';
                  if (accountSettings
                          .value
                          ?.accountSettings
                          ?.appendAnimalDataToURL ==
                      true) {
                    final animalData = widget.animals
                        .map((animal) => 'id=${animal.id}&name=${animal.name}')
                        .join('&');
                    url = '$url?$animalData';
                  }
                  if (url.isNotEmpty) {
                    if (kIsWeb) {
                      // For web platform, directly launch the URL
                      await launchUrl(
                        Uri.parse(url),
                        webOnlyWindowName: '_blank', // Open in a new tab
                      );
                    } else {
                      // For mobile platforms, use WebView
                      final controller = WebViewController()
                        ..setJavaScriptMode(JavaScriptMode.unrestricted)
                        ..loadRequest(Uri.parse(url));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(title: const Text('Custom Form')),
                            body: WebViewWidget(controller: controller),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Custom Form'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountSettings = ref.watch(accountSettingsViewModelProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final appUser = ref.watch(appUserProvider);

    if (accountSettings.value?.accountSettings?.requireEarlyPutBackReason ==
        false) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final currentContext = context;

        // Create logs for all animals
        final logs = widget.animals
            .map(
              (animal) => Log(
                id: const Uuid().v4().toString(),
                type: '',
                author: _nameController.text,
                authorID: appUser?.id ?? '',
                earlyReason: '',
                startTime: Timestamp.now(),
                endTime: Timestamp.now(),
              ),
            )
            .toList();

        // Use bulk operation for faster processing
        final bulkPutBackViewModel = ref.read(bulkPutBackViewModelProvider);
        await bulkPutBackViewModel.bulkPutBackAnimals(widget.animals, logs);

        if (currentContext.mounted) {
          _showThankYouDialog(currentContext);
        }
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
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: animal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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
          if (accountSettings
                      .value
                      ?.accountSettings
                      ?.requireEarlyPutBackReason ==
                  true &&
              shelterSettings
                      .value
                      ?.shelterSettings
                      .earlyPutBackReasons
                      .isNotEmpty ==
                  true &&
              widget.animals.any(
                (animal) =>
                    Timestamp.now()
                        .toDate()
                        .difference(animal.logs.last.startTime.toDate())
                        .inMinutes <
                    accountSettings.value!.accountSettings!.minimumLogMinutes,
              ))
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
                      .value!
                      .shelterSettings
                      .earlyPutBackReasons
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
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
                      return const Center(child: CircularProgressIndicator());
                    },
                  );

                  // Separate animals into those needing deletion vs update
                  final animalsToDeleteLog = <Animal>[];
                  final animalsToUpdate = <Animal>[];
                  final logsToUpdate = <Log>[];

                  for (var animal in widget.animals) {
                    final shouldDeleteLog =
                        ((!accountSettings
                                .value!
                                .accountSettings!
                                .createLogsWhenUnderMinimumDuration &&
                            Timestamp.now()
                                    .toDate()
                                    .difference(
                                      animal.logs.last.startTime.toDate(),
                                    )
                                    .inMinutes <
                                accountSettings
                                    .value!
                                    .accountSettings!
                                    .minimumLogMinutes &&
                            appUser?.type == 'admin') ||
                        (!shelterSettings
                                .value!
                                .volunteerSettings
                                .createLogsWhenUnderMinimumDuration &&
                            Timestamp.now()
                                    .toDate()
                                    .difference(
                                      animal.logs.last.startTime.toDate(),
                                    )
                                    .inMinutes <
                                shelterSettings
                                    .value!
                                    .volunteerSettings
                                    .minimumLogMinutes &&
                            appUser?.type == 'volunteer'));

                    if (shouldDeleteLog) {
                      animalsToDeleteLog.add(animal);
                    } else {
                      animalsToUpdate.add(animal);
                      logsToUpdate.add(
                        Log(
                          id: const Uuid().v4().toString(),
                          type: '',
                          author: _nameController.text,
                          authorID: appUser?.id ?? '',
                          earlyReason: _selectedEarlyReason ?? '',
                          startTime: Timestamp.now(),
                          endTime: Timestamp.now(),
                        ),
                      );
                    }
                  }

                  // Process both operations in parallel for maximum speed
                  final bulkPutBackViewModel = ref.read(
                    bulkPutBackViewModelProvider,
                  );
                  final futures = <Future<void>>[];

                  if (animalsToDeleteLog.isNotEmpty) {
                    futures.add(
                      bulkPutBackViewModel.bulkDeleteLastLogs(
                        animalsToDeleteLog,
                      ),
                    );
                  }

                  if (animalsToUpdate.isNotEmpty) {
                    futures.add(
                      bulkPutBackViewModel.bulkPutBackAnimals(
                        animalsToUpdate,
                        logsToUpdate,
                      ),
                    );
                  }

                  await Future.wait(futures);

                  if (!context.mounted) return;
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
