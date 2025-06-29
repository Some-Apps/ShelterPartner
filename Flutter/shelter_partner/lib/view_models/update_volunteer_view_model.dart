import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/update_volunteer_repository.dart';
import '../models/shelter.dart';

import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class UpdateVolunteerViewModel extends StateNotifier<AsyncValue<Shelter?>> {
  final UpdateVolunteerRepository _repository;
  final Ref ref;
  final LoggerService _logger;

  UpdateVolunteerViewModel(this._repository, this.ref)
    : _logger = ref.read(loggerServiceProvider),
      super(const AsyncValue.loading());

  Future<void> modifyVolunteerLastActivityString(
    String userID,
    String volunteerId,
    String field,
    Timestamp newValue,
  ) async {
    try {
      await _repository.modifyVolunteerLastActivity(userID, newValue);
    } catch (error) {
      _logger.error("Error modifying", error);
      state = AsyncValue.error("Error modifying: $error", StackTrace.current);
    }
  }
}

final shelterSettingsViewModelProvider =
    StateNotifierProvider<UpdateVolunteerViewModel, AsyncValue<Shelter?>>((
      ref,
    ) {
      final repository = ref.watch(
        updateVolunteerRepositoryProvider,
      ); // Access the repository
      return UpdateVolunteerViewModel(
        repository,
        ref,
      ); // Pass the repository and ref
    });
