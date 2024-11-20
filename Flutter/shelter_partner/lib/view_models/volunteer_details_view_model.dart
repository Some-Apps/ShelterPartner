// volunteer_detail_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/repositories/volunteer_details_repository.dart';


class VolunteerDetailState {
  final String averageLogDurationText;
  final String totalTimeLoggedWithAnimalsText;
  final bool isLoading;
  final Volunteer volunteer;

  VolunteerDetailState({
    required this.averageLogDurationText,
    required this.totalTimeLoggedWithAnimalsText,
    required this.isLoading,
    required this.volunteer,
  });

  factory VolunteerDetailState.initial(Volunteer volunteer) {
    return VolunteerDetailState(
      averageLogDurationText: "Loading...",
      totalTimeLoggedWithAnimalsText: "Loading...",
      isLoading: true,
      volunteer: volunteer,
    );
  }

  VolunteerDetailState copyWith({
    String? averageLogDurationText,
    String? totalTimeLoggedWithAnimalsText,
    bool? isLoading,
    Volunteer? volunteer,
  }) {
    return VolunteerDetailState(
      averageLogDurationText: averageLogDurationText ?? this.averageLogDurationText,
      totalTimeLoggedWithAnimalsText:
          totalTimeLoggedWithAnimalsText ?? this.totalTimeLoggedWithAnimalsText,
      isLoading: isLoading ?? this.isLoading,
      volunteer: volunteer ?? this.volunteer,
    );
  }
}


// Define the ViewModel using StateNotifier
class VolunteerDetailViewModel extends StateNotifier<VolunteerDetailState> {
  final Volunteer volunteer;
  final VolunteerDetailsRepository repository; // Updated class name

  VolunteerDetailViewModel({
    required this.volunteer,
    required this.repository,
  }) : super(VolunteerDetailState.initial(volunteer)) {
    // Delay the data fetching until after the first frame
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _fetchLogsAndComputeStats();
    // });

       Future.delayed(const Duration(milliseconds: 500), () {
      _fetchLogsAndComputeStats();
    });
  }

  Future<void> updateVolunteerName(String firstName, String lastName) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.updateVolunteerName(volunteer.shelterID, volunteer.id, firstName, lastName);

      Volunteer updatedVolunteer = volunteer.copyWith(
        firstName: firstName,
        lastName: lastName,
      );

      state = state.copyWith(
        isLoading: false,
        volunteer: updatedVolunteer,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchLogsAndComputeStats() async {
    try {
      Map<String, dynamic> stats =
          await repository.fetchLogsAndComputeStats(volunteer);

      // Format the durations into strings
      String averageLogDurationText = _formatDuration(
        stats['averageLogDuration'],
        'minute',
      );

      String totalTimeLoggedWithAnimalsText = _formatTotalTime(
        stats['totalTimeLoggedWithAnimals'],
      );

      state = state.copyWith(
        averageLogDurationText: averageLogDurationText,
        totalTimeLoggedWithAnimalsText: totalTimeLoggedWithAnimalsText,
        isLoading: false,
      );
    } catch (e) {
      // Handle errors if needed
      state = state.copyWith(
        averageLogDurationText: "Error loading data",
        totalTimeLoggedWithAnimalsText: "Error loading data",
        isLoading: false,
      );
    }
  }

  // Helper method to format durations with singular/plural
  String _formatDuration(double duration, String unit) {
    int roundedDuration = duration.round();
    String unitText = roundedDuration == 1 ? unit : '${unit}s';
    return '$roundedDuration $unitText';
  }

  // Helper method to format total time into minutes, hours, or days
  String _formatTotalTime(int totalMinutes) {
    if (totalMinutes < 60) {
      // Less than an hour
      String unitText = totalMinutes == 1 ? 'minute' : 'minutes';
      return '$totalMinutes $unitText';
    } else if (totalMinutes < 1440) {
      // Less than a day
      double hours = totalMinutes / 60;
      int roundedHours = hours.round();
      String unitText = roundedHours == 1 ? 'hour' : 'hours';
      return '$roundedHours $unitText';
    } else {
      // One day or more
      double days = totalMinutes / 1440;
      int roundedDays = days.round();
      String unitText = roundedDays == 1 ? 'day' : 'days';
      return '$roundedDays $unitText';
    }
  }
}

// Provider for the VolunteerDetailViewModel
final volunteerDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<VolunteerDetailViewModel, VolunteerDetailState, Volunteer>(
  (ref, volunteer) {
    final repository = ref.watch(volunteerRepositoryProvider);
    return VolunteerDetailViewModel(
      volunteer: volunteer,
      repository: repository,
    );
  },
);