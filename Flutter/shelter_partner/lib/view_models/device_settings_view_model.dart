import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/device_settings_repository.dart';
import '../models/shelter.dart';
import 'auth_view_model.dart';

class DeviceSettingsViewModel extends StateNotifier<AsyncValue<AppUser?>> {
  final DeviceSettingsRepository _repository;
  final Ref ref;

  DeviceSettingsViewModel(this._repository, this.ref) : super(const AsyncValue.loading()) {
    _initialize(); // Start the initialization process to fetch account details
  }

  // Initialize and start listening to the account details stream
  void _initialize() {
    final authState = ref.watch(authViewModelProvider);

    // If authenticated, fetch account details based on the shelterID
    if (authState.status == AuthStatus.authenticated) {
      final userID = authState.user?.id;
      if (userID != null) {
        fetchUserDetails(userID: userID);
      } else {
        state = AsyncValue.error('Shelter ID is null', StackTrace.current);
      }
    } else {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
    }
  }


  // Method to fetch account details from the repository
  void fetchUserDetails({required String userID}) {
    _repository.fetchUserDetails(userID).listen((accountDetails) {
      if (accountDetails.exists) {
        state = AsyncValue.data(AppUser.fromDocument(accountDetails)); // Update state with Shelter object
      } else {
        state = AsyncValue.error('No shelter found', StackTrace.current); // Handle case where no shelter is found
      }
    }, onError: (error) {
      state = AsyncValue.error(error, StackTrace.current); // Handle any errors
    });
  }

  // Increment attribute in Firestore document within volunteerSettings
Future<void> incrementAttribute(String userID, String field) async {
  try {
    await _repository.incrementDeviceSetting(userID, field);
  } catch (error) {
    print("Error incrementing: $error");
    state = AsyncValue.error("Error incrementing: $error", StackTrace.current);
  }
}

// Modify attribute in Firestore document within volunteerSettings
Future<void> modifyDeviceSettingString(String userID, String field, String newValue) async {
  try {
    await _repository.modifyDeviceSettingString(userID, field, newValue);
  } catch (error) {
    print("Error modifying: $error");
    state = AsyncValue.error("Error modifying: $error", StackTrace.current);
  }
}


Future<void> toggleAttribute(String userID, String field) async {
  try {
    await _repository.toggleDeviceSetting(userID, field);
  } catch (error) {
    print("Error toggling: $error");
    state = AsyncValue.error("Error toggling: $error", StackTrace.current);
  }
}


Future<void> decrementAttribute(String userID, String field) async {
  try {
    await _repository.decrementDeviceSetting(userID, field);
  } catch (error) {
    print("Error decrementing: $error");
    state = AsyncValue.error("Error decrementing: $error", StackTrace.current);
  }
}

}

// Provider to access the VolunteersViewModel
final deviceSettingsViewModelProvider = StateNotifierProvider<DeviceSettingsViewModel, AsyncValue<AppUser?>>((ref) {
  final repository = ref.watch(deviceSettingsRepositoryProvider); // Access the repository
  return DeviceSettingsViewModel(repository, ref); // Pass the repository and ref
});
