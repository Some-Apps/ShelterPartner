import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/animals_view_model.dart';

class VolunteerPage extends ConsumerStatefulWidget {
  const VolunteerPage({super.key});

  @override
  ConsumerState<VolunteerPage> createState() => _VolunteerPageState();
}

class _VolunteerPageState extends ConsumerState<VolunteerPage> {
  @override
  Widget build(BuildContext context) {
    final animals = ref.watch(animalsViewModelProvider);

    return Scaffold(
      body: Center(
        child: ListView.builder(
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animal = animals[index];
            return ListTile(
              title: Text(animal['name']),
              subtitle: Text("In Kennel: ${animal['inKennel']}"),        
                );
          },
        ),
      ),
    );
  }
}
