import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/volunteer_page_view_model.dart';
import 'package:shelter_partner/views/components/animal_card_view.dart';

class VolunteerPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(volunteerPageProvider);

    return Scaffold(
      body: Builder(
        builder: (context) {
            return Center(child: Text("Volunteer Page"));
        },
      ),
    );
  }
}
