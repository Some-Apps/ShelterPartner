import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/models/filter_condition.dart';
import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/models/volunteer_settings.dart';
import 'package:shelter_partner/repositories/enrichment_repository.dart';
import 'package:shelter_partner/utils/clock.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:rxdart/rxdart.dart';

class EnrichmentViewModel extends StateNotifier<Map<String, List<Animal>>> {
  final EnrichmentRepository _repository;
  final Ref ref;
  final Clock _clock;

  StreamSubscription<void>? _animalsSubscription;

  EnrichmentViewModel(this._repository, this.ref)
    : _clock = ref.read(clockProvider),
      super({'cats': [], 'dogs': []}) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      _onAuthStateChanged(next);
    });

    // Immediately check the current auth state
    final authState = ref.read(authViewModelProvider);
    _onAuthStateChanged(authState);
  }

  DateTime? _ignoreFirestoreUpdatesUntil;

  void _onAuthStateChanged(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      final user = authState.user!;
      final shelterID = user.shelterId;
      if (user.type == 'admin') {
        fetchAnimals(shelterID: shelterID);
      } else if (user.type == 'volunteer') {
        // Immediately fetch if volunteer data already loaded
        final volunteerAsync = ref.read(volunteersViewModelProvider);
        if (volunteerAsync is AsyncData && volunteerAsync.value != null) {
          fetchAnimals(shelterID: shelterID);
        }
        // Listen for transition from not loaded to loaded, then fetch
        ref.listen<AsyncValue<Shelter?>>(volunteersViewModelProvider, (
          previous,
          next,
        ) {
          if (previous is! AsyncData &&
              next is AsyncData &&
              next.value != null) {
            fetchAnimals(shelterID: shelterID);
          }
        });
      }
    } else {
      // Clear animals when not authenticated
      state = {'cats': [], 'dogs': []};
      _animalsSubscription?.cancel();
    }
  }

  // Add fields to store the main filter and secondary filter
  FilterElement? _enrichmentFilter;
  FilterElement? _secondaryFilter;

  // Modify fetchAnimals to apply the filters
  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel(); // Cancel any existing subscription

    // Fetch animals stream
    final animalsStream = _repository.fetchAnimals(shelterID);

    // Fetch account settings stream (filter), seeded with current value to ensure initial emission
    final initialAppUser = ref
        .read(accountSettingsViewModelProvider)
        .asData
        ?.value;
    final accountSettingsStream = ref
        .read(accountSettingsViewModelProvider.notifier)
        .stream
        .map((asyncValue) => asyncValue.asData?.value)
        .startWith(initialAppUser);
    // Fetch volunteer settings stream (filter), seeded with current value to ensure initial emission
    final initialVolunteerSettings = ref
        .read(volunteersViewModelProvider)
        .value
        ?.volunteerSettings;
    final volunteerSettingsStream = ref
        .read(volunteersViewModelProvider.notifier)
        .stream
        .map((asyncValue) => asyncValue.asData!.value?.volunteerSettings)
        .startWith(initialVolunteerSettings);

    // Combine all three streams
    _animalsSubscription =
        CombineLatestStream.combine3<
              List<Animal>,
              AppUser?,
              VolunteerSettings?,
              void
            >(animalsStream, accountSettingsStream, volunteerSettingsStream, (
              animals,
              appUser,
              volunteerSettings,
            ) {
              _enrichmentFilter = appUser?.type == 'admin'
                  ? appUser?.accountSettings?.enrichmentFilter
                  : volunteerSettings?.enrichmentFilter;

              _secondaryFilter = appUser?.userFilter;

              // Apply the filters
              final filteredAnimals = animals.where((animal) {
                final enrichmentFilterResult = _enrichmentFilter != null
                    ? evaluateFilter(_enrichmentFilter!, animal)
                    : true;
                final secondaryFilterResult = _secondaryFilter != null
                    ? evaluateFilter(_secondaryFilter!, animal)
                    : true;
                return enrichmentFilterResult && secondaryFilterResult;
              }).toList();

              final cats = filteredAnimals
                  .where((animal) => animal.species == 'cat')
                  .toList();
              final dogs = filteredAnimals
                  .where((animal) => animal.species == 'dog')
                  .toList();

              if (_ignoreFirestoreUpdatesUntil != null &&
                  _clock.now().isBefore(_ignoreFirestoreUpdatesUntil!)) {
                // Ignore this update - just return without changing state
                print(
                  "Ignoring Firestore update due to recent optimistic update.",
                );
                return;
              }

              state = {'cats': cats, 'dogs': dogs};

              // Sort the animals after fetching and filtering
              _sortAnimals();
            })
            .listen((_) {});
  }

  void updateAnimalOptimistically(Animal updatedAnimal) {
    final currentCats = List<Animal>.from(state['cats'] ?? []);
    final currentDogs = List<Animal>.from(state['dogs'] ?? []);

    // Check which list the animal belongs to and update it
    if (updatedAnimal.species == 'cat') {
      final index = currentCats.indexWhere((a) => a.id == updatedAnimal.id);
      if (index != -1) {
        currentCats[index] = updatedAnimal;
      }
    } else if (updatedAnimal.species == 'dog') {
      final index = currentDogs.indexWhere((a) => a.id == updatedAnimal.id);
      if (index != -1) {
        currentDogs[index] = updatedAnimal;
      }
    }

    final newState = {'cats': currentCats, 'dogs': currentDogs};
    _ignoreFirestoreUpdatesUntil = _clock.now().add(const Duration(seconds: 3));

    state = newState; // This will trigger a rebuild only where it's needed
  }

  void _sortAnimals() {
    final accountSettings = ref
        .read(accountSettingsViewModelProvider)
        .asData
        ?.value;

    final enrichmentSort = (ref.read(appUserProvider)?.type == 'admin')
        ? accountSettings?.accountSettings?.enrichmentSort ?? 'Alphabetical'
        : ref
                  .read(volunteersViewModelProvider)
                  .value
                  ?.volunteerSettings
                  .enrichmentSort ??
              'Alphabetical';

    final sortedState = <String, List<Animal>>{};

    state.forEach((species, animalsList) {
      final sortedList = List<Animal>.from(animalsList);

      if (enrichmentSort == 'Alphabetical') {
        sortedList.sort((a, b) => a.name.compareTo(b.name));
      } else if (enrichmentSort == 'Last Let Out') {
        sortedList.sort(
          (a, b) => a.logs.last.endTime.compareTo(b.logs.last.endTime),
        );
      }

      sortedState[species] = sortedList;
    });

    state = sortedState;
  }

  bool evaluateFilter(FilterElement filter, Animal animal) {
    if (filter is FilterCondition) {
      return evaluateCondition(filter, animal);
    } else if (filter is FilterGroup) {
      return evaluateGroup(filter, animal);
    } else {
      return false;
    }
  }

  bool evaluateCondition(FilterCondition condition, Animal animal) {
    final attributeValue = getAttributeValue(animal, condition.attribute);
    final conditionValue = condition.value;

    if (attributeValue == null) return false;

    final attrLower = conditionValue.toString().toLowerCase();

    switch (condition.operatorType) {
      case OperatorType.equals:
        if (attributeValue is List) {
          return attributeValue.any(
            (e) => e.toString().toLowerCase() == attrLower,
          );
        }
        return attributeValue.toString().toLowerCase() == attrLower;

      case OperatorType.notEquals:
        if (attributeValue is List) {
          return attributeValue.every(
            (e) => e.toString().toLowerCase() != attrLower,
          );
        }
        return attributeValue.toString().toLowerCase() != attrLower;

      case OperatorType.contains:
        if (attributeValue is List) {
          return attributeValue.any(
            (e) => e.toString().toLowerCase().contains(attrLower),
          );
        }
        return attributeValue.toString().toLowerCase().contains(attrLower);

      case OperatorType.notContains:
        if (attributeValue is List) {
          return attributeValue.every(
            (e) => !e.toString().toLowerCase().contains(attrLower),
          );
        }
        return !attributeValue.toString().toLowerCase().contains(attrLower);

      case OperatorType.greaterThan:
        return double.tryParse(attributeValue.toString())! >
            double.tryParse(conditionValue.toString())!;
      case OperatorType.lessThan:
        return double.tryParse(attributeValue.toString())! <
            double.tryParse(conditionValue.toString())!;
      case OperatorType.greaterThanOrEqual:
        return double.tryParse(attributeValue.toString())! >=
            double.tryParse(conditionValue.toString())!;
      case OperatorType.lessThanOrEqual:
        return double.tryParse(attributeValue.toString())! <=
            double.tryParse(conditionValue.toString())!;
      case OperatorType.isTrue:
        return attributeValue == true;
      case OperatorType.isFalse:
        return attributeValue == false;
    }
  }

  bool evaluateGroup(FilterGroup group, Animal animal) {
    if (group.logicalOperator == LogicalOperator.and) {
      return group.elements.every((element) => evaluateFilter(element, animal));
    } else if (group.logicalOperator == LogicalOperator.or) {
      return group.elements.any((element) => evaluateFilter(element, animal));
    } else {
      return false;
    }
  }

  dynamic getAttributeValue(Animal animal, String attribute) {
    switch (attribute) {
      case 'name':
        return animal.name;
      case 'sex':
        return animal.sex;
      case 'species':
        return animal.species;
      case 'tags':
        return animal.tags.map((tag) => tag.title.toLowerCase()).toList();
      case 'notes':
        return animal.notes.map((note) => note.note.toLowerCase()).toList();
      case 'breed':
        return animal.breed;
      case 'location':
        return animal.location;
      case 'description':
        return animal.description;
      case 'symbol':
        return animal.symbol;
      case 'symbolColor':
        return animal.symbolColor;
      case 'takeOutAlert':
        return animal.takeOutAlert;
      case 'putBackAlert':
        return animal.putBackAlert;
      case 'adoptionCategory':
        return animal.adoptionCategory;
      case 'behaviorCategory':
        return animal.behaviorCategory;
      case 'locationCategory':
        return animal.locationCategory;
      case 'medicalCategory':
        return animal.medicalCategory;
      case 'volunteerCategory':
        return animal.volunteerCategory;
      case 'inKennel':
        return animal.inKennel;
      case 'monthsOld':
        return animal.monthsOld;
      case 'letOutType':
        // Assuming last log contains let out type
        return animal.logs.isNotEmpty ? animal.logs.last.type : '';
      case 'earlyPutBackReason':
        // Assuming last log contains early put back reason
        return animal.logs.isNotEmpty ? animal.logs.last.earlyReason : '';
      // Add other attributes as needed
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _animalsSubscription?.cancel();
    super.dispose();
  }
}

final enrichmentViewModelProvider =
    StateNotifierProvider<EnrichmentViewModel, Map<String, List<Animal>>>((
      ref,
    ) {
      final repository = ref.watch(
        enrichmentRepositoryProvider,
      ); // Access the repository
      return EnrichmentViewModel(
        repository,
        ref,
      ); // Pass the repository and ref
    });
