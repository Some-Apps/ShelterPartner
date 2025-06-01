import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/repositories/shelter_details_repository.dart';
import '../models/shelter.dart';
import 'auth_view_model.dart';

class ShelterDetailsViewModel extends StateNotifier<AsyncValue<Shelter?>> {
  final ShelterDetailsRepository _repository;
  final Ref ref;

  ShelterDetailsViewModel(this._repository, this.ref)
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
    _repository
        .fetchShelterDetails(shelterID)
        .listen(
          (accountDetails) {
            if (accountDetails.exists) {
              state = AsyncValue.data(
                Shelter.fromDocument(accountDetails),
              ); // Update state with Shelter object
            } else {
              state = AsyncValue.error(
                'No shelter found',
                StackTrace.current,
              ); // Handle case where no shelter is found
            }
          },
          onError: (error) {
            state = AsyncValue.error(
              error,
              StackTrace.current,
            ); // Handle any errors
          },
        );
  }
}

// Provider for ShelterDetailsViewModel
final shelterDetailsViewModelProvider =
    StateNotifierProvider<ShelterDetailsViewModel, AsyncValue<Shelter?>>((ref) {
      final repository = ref.watch(
        shelterDetailsRepositoryProvider,
      ); // Access the repository
      return ShelterDetailsViewModel(
        repository,
        ref,
      ); // Pass the repository and ref
    });
