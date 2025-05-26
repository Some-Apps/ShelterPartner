import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/shelter_settings_repository.dart';
import 'package:shelter_partner/repositories/volunteers_repository.dart';
import '../models/shelter.dart';
import 'auth_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShelterSettingsViewModel extends StateNotifier<AsyncValue<Shelter?>> {
  final ShelterSettingsRepository _repository;
  final Ref ref;
  final FirebaseFirestore _firestore;

  ShelterSettingsViewModel(this._repository, this.ref, this._firestore)
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

// Toggle attribute in Firestore document within volunteerSettings
  Future<void> toggleAttribute(String shelterID, String field) async {
    try {
      await _repository.toggleShelterSetting(shelterID, field);
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

  // Add string to array within shelterSettings attribute
  Future<void> addStringToShelterSettingsArray(
      String shelterID, String field, String value) async {
    try {
      await _repository.addStringToShelterSettingsArray(
          shelterID, field, value);
    } catch (error) {
      print("Error adding string to array: $error");
      state = AsyncValue.error(
          "Error adding string to array: $error", StackTrace.current);
    }
  }

// Add map to array within shelterSettings attribute
  Future<void> addMapToShelterSettingsArray(
      String shelterID, String field, Map<String, dynamic> value) async {
    try {
      await _repository.addMapToShelterSettingsArray(shelterID, field, value);
    } catch (error) {
      print("Error adding map to array: $error");
      state = AsyncValue.error(
          "Error adding map to array: $error", StackTrace.current);
    }
  }

// Remove string from array within shelterSettings attribute
  Future<void> removeStringFromShelterSettingsArray(
      String shelterID, String field, String value) async {
    try {
      await _repository.removeStringFromShelterSettingsArray(
          shelterID, field, value);
    } catch (error) {
      print("Error removing string from array: $error");
      state = AsyncValue.error(
          "Error removing string from array: $error", StackTrace.current);
    }
  }

// Reorder items in array of maps within shelterSettings attribute
  Future<void> reorderMapArrayInShelterSettings(String shelterID, String field,
      List<Map<String, dynamic>> newOrder) async {
    try {
      await _repository.reorderMapArrayInShelterSettings(
          shelterID, field, newOrder);
    } catch (error) {
      print("Error reordering map array: $error");
      state = AsyncValue.error(
          "Error reordering map array: $error", StackTrace.current);
    }
  }

  Future<void> modifyShelterSettingString(
      String userID, String field, String newValue) async {
    try {
      await _repository.modifyShelterSettingString(userID, field, newValue);
    } catch (error) {
      print("Error modifying: $error");
      state = AsyncValue.error("Error modifying: $error", StackTrace.current);
    }
  }

// Reorder items in array within shelterSettings attribute
  Future<void> reorderShelterSettingsArray(
      String shelterID, String field, List<String> newOrder) async {
    try {
      await _repository.reorderShelterSettingsArray(shelterID, field, newOrder);
    } catch (error) {
      print("Error reordering array: $error");
      state = AsyncValue.error(
          "Error reordering array: $error", StackTrace.current);
    }
  }



// Remove map from array within shelterSettings attribute
  Future<void> removeMapFromShelterSettingsArray(
      String shelterID, String field, Map<String, dynamic> value) async {
    try {
      await _repository.removeMapFromShelterSettingsArray(
          shelterID, field, value);
    } catch (error) {
      print("Error removing map from array: $error");
      state = AsyncValue.error(
          "Error removing map from array: $error", StackTrace.current);
    }
  }

// Increment attribute in Firestore document within volunteerSettings
  Future<void> incrementAttribute(String userID, String field) async {
    try {
      await _repository.incrementShelterSetting(userID, field);
    } catch (error) {
      print("Error incrementing: $error");
      state =
          AsyncValue.error("Error incrementing: $error", StackTrace.current);
    }
  }

  Future<void> decrementAttribute(String userID, String field) async {
    try {
      await _repository.decrementShelterSetting(userID, field);
    } catch (error) {
      print("Error decrementing: $error");
      state =
          AsyncValue.error("Error decrementing: $error", StackTrace.current);
    }
  }

  // Method to reset token count
  Future<void> resetTokenCount(String shelterID) async {
    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.tokenCount': 0,
      'shelterSettings.lastTokenReset': DateTime.now().toIso8601String(),
    }).catchError((error) {
      throw Exception("Failed to reset token count: $error");
    });
  }

  // Method to check if tokens need to be reset
  Future<void> checkAndResetTokens(String shelterID) async {
    final shelterSettings = state.value?.shelterSettings;
    if (shelterSettings == null) return;

    final lastReset = shelterSettings.lastTokenReset;
    if (lastReset == null) {
      // If no last reset date, set it to now and reset tokens
      await resetTokenCount(shelterID);
      return;
    }

    final now = DateTime.now();
    // For testing: use 1 minute instead of 30 days
    const testMode = true;
    final daysSinceLastReset = testMode 
        ? now.difference(lastReset).inMinutes  // Test with minutes
        : now.difference(lastReset).inDays;    // Production with days
    
    if (testMode ? daysSinceLastReset >= 1 : daysSinceLastReset >= 30) {
      await resetTokenCount(shelterID);
    }
  }

  // Method to increment token count
  Future<void> incrementTokenCount(String shelterID, int tokens) async {
    // Check if tokens need to be reset before incrementing
    await checkAndResetTokens(shelterID);

    final docRef = _firestore.collection('shelters').doc(shelterID);
    return docRef.update({
      'shelterSettings.tokenCount': FieldValue.increment(tokens),
    }).catchError((error) {
      throw Exception("Failed to increment token count: $error");
    });
  }

  Future<void> updateTokenCount(String shelterId, int newCount) async {
    await _repository.updateTokenCount(shelterId, newCount);
    state = AsyncData(state.value!.copyWith(
      shelterSettings: state.value!.shelterSettings.copyWith(
        tokenCount: newCount,
      ),
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Provider to access the ShelterSettingsViewModel
final shelterSettingsViewModelProvider =
    StateNotifierProvider<ShelterSettingsViewModel, AsyncValue<Shelter?>>(
        (ref) {
  final repository =
      ref.watch(shelterSettingsRepositoryProvider); // Access the repository
  final firestore = FirebaseFirestore.instance;
  return ShelterSettingsViewModel(
      repository, ref, firestore); // Pass the repository, ref, and firestore
});
