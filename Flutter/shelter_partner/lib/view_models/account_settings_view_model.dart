import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/account_settings_repository.dart';
import 'auth_view_model.dart';
import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class AccountSettingsViewModel extends StateNotifier<AsyncValue<AppUser?>> {
  final AccountSettingsRepository _repository;
  final Ref ref;
  final LoggerService _logger;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  AccountSettingsViewModel(this._repository, this.ref, this._logger)
    : super(const AsyncValue.loading()) {
    // Listen to authentication state changes
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      _onAuthStateChanged(next);
    });

    // Immediately check the current auth state
    final authState = ref.read(authViewModelProvider);
    _onAuthStateChanged(authState);
  }

  void _onAuthStateChanged(AuthState authState) {
    _userSubscription?.cancel(); // Cancel any existing subscription

    if (authState.status == AuthStatus.authenticated) {
      final userID = authState.user?.id;
      if (userID != null) {
        fetchUserDetails(userID: userID);
      } else {
        state = AsyncValue.error('User ID is null', StackTrace.current);
      }
    } else {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
    }
  }

  // Method to fetch account details from the repository
  void fetchUserDetails({required String userID}) {
    _userSubscription = _repository
        .fetchUserDetails(userID)
        .listen(
          (accountDetails) {
            if (accountDetails.exists) {
              state = AsyncValue.data(AppUser.fromDocument(accountDetails));
            } else {
              state = AsyncValue.error('No user found', StackTrace.current);
            }
          },
          onError: (error) {
            state = AsyncValue.error(error, StackTrace.current);
          },
        );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // Other methods...

  // Modify attribute in Firestore document within volunteerSettings
  Future<void> modifyAccountSettingString(
    String userID,
    String field,
    String newValue,
  ) async {
    try {
      await _repository.modifyAccountSettingString(userID, field, newValue);
    } catch (error) {
      _logger.error("Error modifying", error);
      state = AsyncValue.error("Error modifying: $error", StackTrace.current);
    }
  }

  Future<void> toggleAttribute(String userID, String field) async {
    try {
      await _repository.toggleAccountSetting(userID, field);
    } catch (error) {
      _logger.error("Error toggling", error);
      state = AsyncValue.error("Error toggling: $error", StackTrace.current);
    }
  }

  Future<int?> getLocationTierCount(String userID) async {
    try {
      final data = await _repository.getLocationTierCount(
        userID,
        'locationTierCount',
      );
      return data;
    } catch (error) {
      _logger.error("Error reading locationTierCount", error);
      state = AsyncValue.error(
        "Error reading locationTierCount: $error",
        StackTrace.current,
      );
      return null;
    }
  }

  Future<void> updateLocationTierCount(String userID, int count) async {
    try {
      await _repository.updateLocationTierCount(userID, count);
    } catch (error) {
      _logger.error("Error updating locationTierCount", error);
      state = AsyncValue.error(
        "Error updating locationTierCount: $error",
        StackTrace.current,
      );
    }
  }

  // Increment attribute in Firestore document within volunteerSettings
  Future<void> incrementAttribute(String userID, String field) async {
    try {
      await _repository.incrementAccountSetting(userID, field);
    } catch (error) {
      _logger.error("Error incrementing", error);
      state = AsyncValue.error(
        "Error incrementing: $error",
        StackTrace.current,
      );
    }
  }

  Future<void> decrementAttribute(String userID, String field) async {
    try {
      await _repository.decrementAccountSetting(userID, field);
    } catch (error) {
      _logger.error("Error decrementing", error);
      state = AsyncValue.error(
        "Error decrementing: $error",
        StackTrace.current,
      );
    }
  }

  Future<void> saveFilterExpression(
    List<Map<String, dynamic>> serializedFilterElements,
    Map<String, String> serializedOperatorsBetween,
  ) async {
    final authState = ref.read(authViewModelProvider);
    if (authState.status == AuthStatus.authenticated) {
      final userID = authState.user?.id;
      if (userID != null) {
        await _repository.saveFilterExpression(userID, {
          'filterElements': serializedFilterElements,
          'operatorsBetween': serializedOperatorsBetween,
        });
      }
    }
  }

  Future<Map<String, dynamic>?> loadFilterExpression() async {
    final authState = ref.read(authViewModelProvider);
    if (authState.status == AuthStatus.authenticated) {
      final userID = authState.user?.id;
      if (userID != null) {
        final result = await _repository.loadFilterExpression(userID);
        return result;
      }
    }
    return null;
  }
}

// Provider to access the VolunteersViewModel
final accountSettingsViewModelProvider =
    StateNotifierProvider<AccountSettingsViewModel, AsyncValue<AppUser?>>((
      ref,
    ) {
      final repository = ref.watch(
        accountSettingsRepositoryProvider,
      ); // Access the repository
      final logger = ref.watch(loggerServiceProvider);
      return AccountSettingsViewModel(
        repository,
        ref,
        logger,
      ); // Pass the repository and ref
    });
