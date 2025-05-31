import 'package:flutter/material.dart';

class NumberStepperView extends StatelessWidget {
  final String title;
  final int value; // Pass the actual current value of the stepper
  final String label;
  final int minValue; // Minimum value for the stepper
  final int maxValue; // Maximum value for the stepper
  final VoidCallback increment; // Custom increment function
  final VoidCallback decrement; // Custom decrement function

  const NumberStepperView({
    super.key,
    required this.title,
    required this.value, // Pass the value from the parent
    this.label = '',
    required this.minValue, // Ensure minimum value is passed
    required this.maxValue, // Ensure maximum value is passed
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
          onPressed: value > minValue
              ? decrement
              : null, // Disable if value <= minValue
        ),
        Text('$value $label'), // Display the passed value
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < maxValue
              ? increment
              : null, // Disable if value >= maxValue
        ),
      ],
    );
  }
}
