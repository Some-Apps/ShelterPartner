import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/view_models/volunteer_details_view_model.dart';
// volunteer_detail_page.dart


class VolunteerDetailPage extends ConsumerWidget {
  final Volunteer volunteer;

  const VolunteerDetailPage({super.key, required this.volunteer});

  // timeSince function
  String _timeSince(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      int days = difference.inDays;
      String unitText = days == 1 ? 'day' : 'days';
      return "$days $unitText ago";
    } else if (difference.inHours > 0) {
      int hours = difference.inHours;
      String unitText = hours == 1 ? 'hour' : 'hours';
      return "$hours $unitText ago";
    } else if (difference.inMinutes > 0) {
      int minutes = difference.inMinutes;
      String unitText = minutes == 1 ? 'minute' : 'minutes';
      return "$minutes $unitText ago";
    } else {
      return "Just now";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the ViewModel's state
    final viewModelState = ref.watch(
      volunteerDetailViewModelProvider(volunteer),
    );

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
            ListTile(
              title: const Text("Average Log Duration"),
              subtitle: Text(viewModelState.averageLogDurationText),
            ),
            ListTile(
              title: const Text("Total Time Logged With Animals"),
              subtitle: Text(viewModelState.totalTimeLoggedWithAnimalsText),
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
}
