import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/animal_repository.dart';

// Use ChangeNotifierProvider since VolunteerPageViewModel extends ChangeNotifier
final volunteerPageProvider = ChangeNotifierProvider((ref) {
  final animalRepository = ref.watch(animalRepositoryProvider);
  return VolunteerPageViewModel(animalRepository: animalRepository);
});


class VolunteerPageViewModel extends ChangeNotifier {
  final AnimalRepository _animalRepository;
  List<Animal> _animals = [];

  List<Animal> get animals => _animals;

  VolunteerPageViewModel({required AnimalRepository animalRepository})
      : _animalRepository = animalRepository;

  // Fetch both cats and dogs from Firestore and combine the lists
  Future<void> fetchAllAnimals(String shelterId) async {
    print('Fetching all animals (cats and dogs) for shelterId: $shelterId');
    
    try {
      final catsStream = _animalRepository.getAnimalsStream(shelterId: shelterId, animalType: 'cats');
      final dogsStream = _animalRepository.getAnimalsStream(shelterId: shelterId, animalType: 'dogs');

      final catsList = await catsStream.first;
      final dogsList = await dogsStream.first;

      _animals = [...catsList, ...dogsList];
      notifyListeners();  // Notify listeners after updating the list
    } catch (e) {
      print('Error fetching animals: $e');
    }
  }
}
