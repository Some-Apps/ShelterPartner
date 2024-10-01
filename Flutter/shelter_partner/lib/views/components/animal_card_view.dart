import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/animal_repository.dart';
import 'package:shelter_partner/view_models/animal_card_view_model.dart';


class AnimalCardView extends StatelessWidget {
  final Animal animal;

  AnimalCardView({required this.animal});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AnimalCardViewModel(animal: animal, animalRepository: context.read<AnimalRepository>()),
      child: Consumer<AnimalCardViewModel>(
        builder: (context, viewModel, child) {
          return Card(
            elevation: 2.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(viewModel.animal.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Location: ${viewModel.animal.location}"),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () {
                      print("Do something");
                    },
                    child: Text("Button"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
