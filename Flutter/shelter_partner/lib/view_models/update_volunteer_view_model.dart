import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/update_volunteer_repository.dart';
import '../models/shelter.dart';
import 'auth_view_model.dart';

class UpdateVolunteerViewModel extends StateNotifier<AsyncValue<Shelter?>> {
  final UpdateVolunteerRepository _repository;
  final Ref ref;

  UpdateVolunteerViewModel(this._repository, this.ref)
      : super(const AsyncValue.loading()) {
    _initialize(); // Start the initialization process to fetch account details
  }

  // Initialize and start listening to the account details stream
  void _initialize() {
    final authState = ref.watch(authViewModelProvider);

    // If authenticated, fetch account details based on the shelterID
    if (authState.status == AuthStatus.authenticated) {
      final shelterID = authState.user?.shelterId;
      if (shelterID != null) {
        fetchShelterDetails(shelterID: shelterID);
      } else {
        state = AsyncValue.error('Shelter ID is null', StackTrace.current);
      }
    } else {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
    }
  }


  // Method to fetch account details from the repository
  void fetchShelterDetails({required String shelterID}) {
    _repository.fetchShelterDetails(shelterID).listen((accountDetails) {
      if (accountDetails.exists) {
        state = AsyncValue.data(Shelter.fromDocument(
            accountDetails)); // Update state with Shelter object
      } else {
        state = AsyncValue.error('No shelter found',
            StackTrace.current); // Handle case where no shelter is found
      }
    }, onError: (error) {
      state = AsyncValue.error(error, StackTrace.current); // Handle any errors
    });
  }



  Future<void> modifyVolunteerSettingString(
      String userID, String volunteerId, String field, Timestamp newValue) async {
    try {
      await _repository.modifyVolunteerLastActivity(userID, volunteerId, field, newValue); 
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
