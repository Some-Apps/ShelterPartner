import 'package:flutter/material.dart';

/// A helper class to manage confirmation and error dialogs.
///
/// All dialog-related code is encapsulated within this class to keep
/// other widgets clean and maintain separation of concerns.
class PutBackConfirmationView {
  /// Shows a confirmation dialog with predefined title, content, and actions.
  ///
  /// Returns `true` if the user confirms, `false` if the user cancels, or `null` if dismissed.
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String animalName,
    required bool inKennel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to ${inKennel ? 'take $animalName out of the kennel' : 'put $animalName back in the kennel'}?',
              ),
              const SizedBox(height: 20),
              // Example of adding a custom text field
              TextField(
                controller: TextEditingController(),
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
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
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  /// Shows an error dialog with predefined title and message.
  ///
  /// This dialog only has an "OK" button to dismiss.
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss error dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
