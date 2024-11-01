import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/repositories/add_log_repository.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';

class AddLogViewModel extends StateNotifier<Animal> {
  final AddLogRepository _repository;
  final Ref ref;
  

  AddLogViewModel(this._repository, this.ref, Animal animal) : super(animal);

  Future<void> addLogToAnimal(Animal animal, Log log) async {
    print(log.toMap());
        // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    try {
      await _repository.addLogToAnimal(animal, shelterDetailsAsync.value!.id, log);
      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      print('Failed to add note: $e');
    }
  }

  
}

// Provider for AddNoteViewModel
final addLogViewModelProvider =
    StateNotifierProvider.family<AddLogViewModel, Animal, Animal>(
  (ref, animal) {
    final repository = ref.watch(addLogRepositoryProvider);
    return AddLogViewModel(repository, ref, animal);
  },
);
