import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/animals_view_model.dart';
import 'package:shelter_partner/views/components/animal_card_view.dart';

class AnimalsPage extends ConsumerStatefulWidget {
  const AnimalsPage({super.key});

  @override
  ConsumerState<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends ConsumerState<AnimalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedAnimalType = 'dogs'; // Default selection

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {
      selectedAnimalType = _tabController.index == 0 ? 'dogs' : 'cats';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animalsMap = ref.watch(animalsViewModelProvider);
    final animals = animalsMap[selectedAnimalType] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Animals"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dogs'),
            Tab(text: 'Cats'),
          ],
        ),
      ),
      body: animals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate the number of columns based on the screen width
                  final int columns = (constraints.maxWidth / 350).floor();
                  // Calculate the aspect ratio based on the width
                  final double aspectRatio = constraints.maxWidth / (columns * 200);

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: aspectRatio, // Adjust the aspect ratio dynamically
                    ),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      return AnimalCardView(animal: animal);
                    },
                  );
                },
              ),
            ),
    );
  }
}
