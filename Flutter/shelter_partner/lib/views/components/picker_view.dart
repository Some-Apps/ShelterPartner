import 'package:flutter/material.dart';

class PickerView extends StatelessWidget {
  final String title; // Title for the picker
  final List<String> options; // List of options for the picker
  final String?
  value; // Currently selected value (nullable in case it's not in the list)
  final ValueChanged<String?> onChanged; // Callback for handling value change

  const PickerView({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value, // The currently selected value
        hint: const Text(
          "Select an option",
        ), // Placeholder text when no value is selected
        onChanged: onChanged, // Handle value change
        items: options.map<DropdownMenuItem<String>>((String option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
      ),
    );
  }
}
