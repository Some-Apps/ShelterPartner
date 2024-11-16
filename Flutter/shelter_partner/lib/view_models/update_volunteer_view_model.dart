import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/update_volunteer_repository.dart';
import '../models/shelter.dart';
import 'auth_view_model.dart';

class UpdateVolunteerViewModel extends StateNotifier<AsyncValue<Shelter?>> {
  final UpdateVolunteerRepository _repository;
  final Ref ref;

  UpdateVolunteerViewModel(this._repository, this.ref)
      : super(const AsyncValue.loading());



  Future<void> modifyVolunteerLastActivityString(
      String userID, String volunteerId, String field, Timestamp newValue) async {
    try {
      await _repository.modifyVolunteerLastActivity(userID, newValue); 
    } catch (error) {
      print("Error modifying: $error");
      state = AsyncValue.error("Error modifying: $error", StackTrace.current);
    }
  }

}

final shelterSettingsViewModelProvider =
    StateNotifierProvider<UpdateVolunteerViewModel, AsyncValue<Shelter?>>(
        (ref) {
  final repository =
      ref.watch(updateVolunteerRepositoryProvider); // Access the repository
  return UpdateVolunteerViewModel(
      repository, ref); // Pass the repository and ref
});
