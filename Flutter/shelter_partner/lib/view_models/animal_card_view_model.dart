import 'package:flutter/material.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/animal_repository.dart';


class AnimalCardViewModel extends ChangeNotifier {
  final AnimalRepository _animalRepository;
  Animal animal;

  AnimalCardViewModel({required Animal animal, required AnimalRepository animalRepository})
      : animal = animal,
        _animalRepository = animalRepository;

}
