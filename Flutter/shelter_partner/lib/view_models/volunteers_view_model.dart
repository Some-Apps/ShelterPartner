import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/volunteers_repository.dart';
import '../models/shelter.dart';
import 'auth_view_model.dart';

class VolunteersViewModel extends StateNotifier<AsyncValue<Shelter?>> {
  final VolunteersRepository _repository;
  final Ref ref;

  VolunteersViewModel(this._repository, this.ref)
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

  // Method to change geofence settings in Firestore document within volunteerSettings
  Future<void> changeGeofence(
      String shelterID, GeoPoint location, double radius, double zoom) async {
    try {
      await _repository.changeGeofence(shelterID, location, radius, zoom);
    } catch (error) {
      print("Error changing geofence: $error");
      state = AsyncValue.error(
          "Error changing geofence: $error", StackTrace.current);
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

  // Increment attribute in Firestore document within volunteerSettings
  Future<void> incrementAttribute(String shelterID, String field) async {
    try {
      await _repository.incrementVolunteerSetting(shelterID, field);
    } catch (error) {
      print("Error incrementing: $error");
      state =
          AsyncValue.error("Error incrementing: $error", StackTrace.current);
    }
  }

// Modify attribute in Firestore document within volunteerSettings
  Future<void> modifyVolunteerSettingString(
      String shelterID, String field, String newValue) async {
    try {
      await _repository.modifyVolunteerSettingString(
          shelterID, field, newValue);
    } catch (error) {
      print("Error modifying: $error");
      state = AsyncValue.error("Error modifying: $error", StackTrace.current);
    }
  }

// Toggle attribute in Firestore document within volunteerSettings
  Future<void> toggleAttribute(String shelterID, String field) async {
    try {
      await _repository.toggleVolunteerSetting(shelterID, field);
    } catch (error) {
      print("Error toggling: $error");
      state = AsyncValue.error("Error toggling: $error", StackTrace.current);
    }
  }

  Future<void> sendVolunteerInvite(
      String firstName, String lastName, String email, String shelterID) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(volunteersRepositoryProvider)
          .sendVolunteerInvite(firstName, lastName, email, shelterID);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteVolunteer(String id, String shelterId) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(volunteersRepositoryProvider)
          .deleteVolunteer(id, shelterId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

// Decrement attribute in Firestore document within volunteerSettings
  Future<void> decrementAttribute(String shelterID, String field) async {
    try {
      await _repository.decrementVolunteerSetting(shelterID, field);
    } catch (error) {
      print("Error decrementing: $error");
      state =
          AsyncValue.error("Error decrementing: $error", StackTrace.current);
    }
  }
}

// Provider to access the VolunteersViewModel
final volunteersViewModelProvider =
    StateNotifierProvider<VolunteersViewModel, AsyncValue<Shelter?>>((ref) {
  final repository =
      ref.watch(volunteersRepositoryProvider); // Access the repository
  return VolunteersViewModel(repository, ref); // Pass the repository and ref
});
