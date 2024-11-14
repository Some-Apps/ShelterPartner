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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text("Name"),
              subtitle: Text("${volunteer.firstName} ${volunteer.lastName}"),
            ),
            ListTile(
              title: const Text("Email"),
              subtitle: Text(volunteer.email),
            ),
            const SizedBox(height: 10),
            const ListTile(
              title: Text("Average Log Duration"),
              subtitle: Text("24 minutes"),
            ),
            const ListTile(
              title: Text("Total Time Logged With Animals"),
              subtitle: Text("319 hours"),
            ),
            ListTile(
              title: const Text("Last Time At Shelter"),
                subtitle: Text(_timeSince(volunteer.lastActivity.toDate())),
            ),
          ],
        ),
      ),
      
    );
  }

  // timeSince function
  String _timeSince(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      return "${difference.inDays} days ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hours ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minutes ago";
    } else {
      return "Just now";
    }
  }
}
