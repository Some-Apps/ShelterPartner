import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/animal_repository.dart';
import 'package:shelter_partner/view_models/volunteer_page_view_model.dart';
import 'package:shelter_partner/views/components/animal_card_view.dart';

class VolunteerPage extends StatefulWidget {
  @override
  _VolunteerPageState createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> {
  @override
  Widget build(BuildContext context) {
    // Access the user object from the provider
    final user = Provider.of<AppUser>(context);
    final shelterId = user.shelterId;  // Now you have access to shelterId globally
    print('Rendering VolunteerPage with shelterId: $shelterId');

    // Provide AnimalRepository so it's accessible throughout the widget tree
    return MultiProvider(
      providers: [
        Provider<AnimalRepository>(
          create: (context) => AnimalRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) => VolunteerPageViewModel(
            animalRepository: Provider.of<AnimalRepository>(context, listen: false),
          )..fetchAllAnimals(shelterId), // Fetch both cats and dogs
        ),
      ],
      child: Scaffold(
        body: Consumer<VolunteerPageViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.animals.isEmpty) {
              print('No animals to display');
              return Center(child: CircularProgressIndicator());
            }

            print('Displaying ${viewModel.animals.length} animals');
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: viewModel.animals.length,
              itemBuilder: (context, index) {
                final animal = viewModel.animals[index];
                print('Displaying animal: ${animal.name}');
                return AnimalCardView(animal: animal);
              },
            );
          },
        ),
      ),
    );
  }
}
