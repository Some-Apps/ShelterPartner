import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/repositories/animals_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class AnimalsViewModel extends StateNotifier<List<Animal>> {
  final AnimalsRepository _repository;
  final Ref ref;

  AnimalsViewModel(this._repository, this.ref) : super([]) {
    _initialize(); // Start the initialization process to fetch animals
  }

  void _initialize() {
    final authState = ref.watch(authViewModelProvider);
    if (authState.status == AuthStatus.authenticated) {
      final shelterID = authState.user?.shelterId;
      print("shelterID: $shelterID"); // Debug print
      if (shelterID != null) {
        fetchAnimals(shelterID: shelterID);
      }
    }
  }

  void fetchAnimals({required String shelterID}) {
    _repository.fetchAnimals(shelterID).listen((animals) {
      print("Fetched animals: ${animals.length}"); // Debug print
      state = animals; // Update the state with the fetched animals
    });
  }
}

// Create a provider for the AnimalsViewModel
final animalsViewModelProvider = StateNotifierProvider<AnimalsViewModel, List<Animal>>((ref) {
  final repository = ref.watch(animalsRepositoryProvider); // Access the repository
  return AnimalsViewModel(repository, ref); // Pass the repository and ref
});
