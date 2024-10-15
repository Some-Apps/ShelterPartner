import 'package:flutter/material.dart';

class VolunteerDetailPage extends StatelessWidget {
  final String id;
  const VolunteerDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Volunteer Details"),
      ),
      body: Center(
        child: Text("Volunteer Details $id"),
      ),
    );
  }
}
