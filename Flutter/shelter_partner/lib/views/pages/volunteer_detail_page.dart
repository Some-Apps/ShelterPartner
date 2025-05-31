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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: [
                ListTile(
                  title: const Text("Name"),
                  subtitle: Row(
                    children: [
                      Text(
                        "${viewModelState.volunteer.firstName} ${viewModelState.volunteer.lastName}",
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showEditNameDialog(
                              context, ref, viewModelState.volunteer);
                        },
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
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
        ),
      ),
    );
  }
}

void _showEditNameDialog(
    BuildContext context, WidgetRef ref, Volunteer volunteer) {
  String newFirstName = volunteer.firstName;
  String newLastName = volunteer.lastName;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: newFirstName,
              onChanged: (value) {
                newFirstName = value;
              },
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextFormField(
              initialValue: newLastName,
              onChanged: (value) {
                newLastName = value;
              },
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              await ref
                  .read(volunteerDetailViewModelProvider(volunteer).notifier)
                  .updateVolunteerName(newFirstName, newLastName);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
