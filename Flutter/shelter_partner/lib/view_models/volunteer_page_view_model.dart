import 'package:flutter/material.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/animal_repository.dart';

class VolunteerPageViewModel extends ChangeNotifier {
  final AnimalRepository _animalRepository;
  List<Animal> _animals = [];

  List<Animal> get animals => _animals;

  VolunteerPageViewModel({required AnimalRepository animalRepository})
      : _animalRepository = animalRepository;

  // Fetch both cats and dogs from Firestore and combine the lists
  void fetchAllAnimals(String shelterId) {
    print('Fetching all animals (cats and dogs) for shelterId: $shelterId');
    
    final catsStream = _animalRepository.getAnimalsStream(shelterId: shelterId, animalType: 'cats');
    final dogsStream = _animalRepository.getAnimalsStream(shelterId: shelterId, animalType: 'dogs');

    catsStream.listen((catsList) {
      _animals = catsList;  // Add cats first
      notifyListeners();
    });

    dogsStream.listen((dogsList) {
      _animals.addAll(dogsList);  // Add dogs to the existing list
      notifyListeners();
    });
  }
}
