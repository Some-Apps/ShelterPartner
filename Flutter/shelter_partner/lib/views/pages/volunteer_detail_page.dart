
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class VolunteerDetailPage extends StatelessWidget {
  const VolunteerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Volunteer Details"),
      ),
      body: const Center(
        child: Text("Volunteer Details"),
      ),
    );
  }
}