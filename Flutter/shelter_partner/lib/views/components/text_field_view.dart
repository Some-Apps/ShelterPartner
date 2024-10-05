import 'package:flutter/material.dart';

class TextFieldView extends StatefulWidget {
  final String title;  // Title for the text field
  final String hint;   // Placeholder hint for the text field
  final String value;  // Initial value of the text field
  final ValueChanged<String> onSaved;  // Callback for handling save

  const TextFieldView({
    super.key,
    required this.title,
    required this.hint,
    required this.value,
    required this.onSaved,
  });

  @override
  _TextFieldViewState createState() => _TextFieldViewState();
}

class _TextFieldViewState extends State<TextFieldView> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);  // Initialize the controller with the initial value
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,  // Display the title
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hint,  // Placeholder hint
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                widget.onSaved(_controller.text);  // Call the callback with the current value
                FocusScope.of(context).unfocus();  // Unfocus the text field
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
