import 'package:flutter/material.dart';

class NumberStepperView extends StatelessWidget {
  final String title;
  final int value; // Pass the actual current value of the stepper
  final String label;
  final VoidCallback increment; // Custom increment function
  final VoidCallback decrement; // Custom decrement function

  const NumberStepperView({
    super.key,
    required this.title,
    required this.value, // Pass the value from the parent
    this.label = '',
    required this.increment, // Ensure custom increment is passed
    required this.decrement, // Ensure custom decrement is passed
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 0 ? decrement : null, // Disable if value <= 0
        ),
        Text('$value $label'), // Display the passed value
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: increment, // Use custom increment function
        ),
      ],
    );
  }
}
