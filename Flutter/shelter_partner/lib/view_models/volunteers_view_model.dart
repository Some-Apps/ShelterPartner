import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/volunteers_repository.dart';
import '../models/shelter.dart';
import 'auth_view_model.dart';

import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class VolunteersViewModel extends StateNotifier<AsyncValue<Shelter?>> {
  final VolunteersRepository _repository;
  final Ref ref;
  final LoggerService _logger;
  StreamSubscription<Shelter>? _shelterSubscription;

  VolunteersViewModel(this._repository, this.ref)
    : _logger = ref.read(loggerServiceProvider),
      super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    final authState = ref.watch(authViewModelProvider);
    if (authState.status == AuthStatus.authenticated) {
      final shelterID = authState.user?.shelterId;
      if (shelterID != null) {
        _shelterSubscription = _repository
            .fetchShelterWithVolunteers(shelterID)
            .listen(
              (shelter) {
                state = AsyncValue.data(shelter);
              },
              onError: (error) {
                state = AsyncValue.error(error, StackTrace.current);
              },
            );
      } else {
        state = AsyncValue.error('Shelter ID is null', StackTrace.current);
      }
    } else {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
    }
  }

  @override
  void dispose() {
    _shelterSubscription?.cancel();
    super.dispose();
  }

  // Method to change geofence settings in Firestore document within volunteerSettings
  Future<void> changeGeofence(
    String shelterID,
    GeoPoint location,
    double radius,
    double zoom,
  ) async {
    try {
      await _repository.changeGeofence(shelterID, location, radius, zoom);
    } catch (error) {
      _logger.error("Error changing geofence", error);
      state = AsyncValue.error(
        "Error changing geofence: $error",
        StackTrace.current,
      );
    }
  }

  // Increment attribute in Firestore document within volunteerSettings
  Future<void> incrementAttribute(String shelterID, String field) async {
    try {
      await _repository.incrementVolunteerSetting(shelterID, field);
    } catch (error) {
      _logger.error("Error incrementing", error);
      state = AsyncValue.error(
        "Error incrementing: $error",
        StackTrace.current,
      );
    }
  }

  // Modify attribute in Firestore document within volunteerSettings
  Future<void> modifyVolunteerSettingString(
    String shelterID,
    String field,
    String newValue,
  ) async {
    try {
      await _repository.modifyVolunteerSettingString(
        shelterID,
        field,
        newValue,
      );
    } catch (error) {
      _logger.error("Error modifying", error);
      state = AsyncValue.error("Error modifying: $error", StackTrace.current);
    }
  }

  // Toggle attribute in Firestore document within volunteerSettings
  Future<void> toggleAttribute(String shelterID, String field) async {
    try {
      await _repository.toggleVolunteerSetting(shelterID, field);
    } catch (error) {
      _logger.error("Error toggling", error);
      state = AsyncValue.error("Error toggling: $error", StackTrace.current);
    }
  }

  Future<void> sendVolunteerInvite(
    String firstName,
    String lastName,
    String email,
    String shelterID,
  ) async {
    try {
      await ref
          .read(volunteersRepositoryProvider)
          .sendVolunteerInvite(firstName, lastName, email, shelterID);
    } catch (e) {
      // Handle error appropriately, perhaps by showing a SnackBar or dialog
    }
  }

  Future<void> deleteVolunteer(String id, String shelterId) async {
    try {
      await ref
          .read(volunteersRepositoryProvider)
          .deleteVolunteer(id, shelterId);
    } catch (e) {
      // Handle error appropriately, perhaps by showing a SnackBar or dialog
    }
  }

  // Decrement attribute in Firestore document within volunteerSettings
  Future<void> decrementAttribute(String shelterID, String field) async {
    try {
      await _repository.decrementVolunteerSetting(shelterID, field);
    } catch (error) {
      _logger.error("Error decrementing", error);
      state = AsyncValue.error(
        "Error decrementing: $error",
        StackTrace.current,
      );
    }
  }
}

// Provider to access the VolunteersViewModel
final volunteersViewModelProvider =
    StateNotifierProvider<VolunteersViewModel, AsyncValue<Shelter?>>((ref) {
      final repository = ref.watch(
        volunteersRepositoryProvider,
      ); // Access the repository
      return VolunteersViewModel(
        repository,
        ref,
      ); // Pass the repository and ref
    });
