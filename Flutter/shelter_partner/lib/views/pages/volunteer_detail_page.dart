import 'package:flutter/material.dart';
import 'package:shelter_partner/models/volunteer.dart';

class VolunteerDetailPage extends StatelessWidget {
  final Volunteer volunteer;
  const VolunteerDetailPage({super.key, required this.volunteer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Volunteer Details"),
      ),
      body: Center(
        child: Text("Volunteer Details ${volunteer.email}"),
      ),
    );
  }
}
