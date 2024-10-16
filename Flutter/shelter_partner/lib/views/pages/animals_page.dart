import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/animals_view_model.dart';

class AnimalsPage extends ConsumerStatefulWidget {
  const AnimalsPage({super.key});

  @override
  ConsumerState<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends ConsumerState<AnimalsPage> {
  @override
  Widget build(BuildContext context) {
    final animals = ref.watch(animalsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Animals"),
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
