import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/animals_view_model.dart';

class VisitorPage extends ConsumerStatefulWidget {
  const VisitorPage({super.key});

  @override
  ConsumerState<VisitorPage> createState() => _VisitorPageState();
}

class _VisitorPageState extends ConsumerState<VisitorPage> {
  @override
  Widget build(BuildContext context) {
    final animals = ref.watch(animalsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor (only admin accounts)"),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animal = animals[index];
            return ListTile(
              title: Text(animal.name),
              subtitle: Text(animal.toString()),

                );
          },
        ),
      ),
    );
  }
}