import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/models/filter_condition.dart';
import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/repositories/visitors_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:rxdart/rxdart.dart';

class VisitorsViewModel extends StateNotifier<Map<String, List<Animal>>> {
  final VisitorsRepository _repository;
  final Ref ref;

  StreamSubscription<void>? _animalsSubscription;

  VisitorsViewModel(this._repository, this.ref)
    : super({'cats': [], 'dogs': []}) {
    // Listen to authentication state changes
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      _onAuthStateChanged(next);
    });

    // Immediately check the current auth state
    final authState = ref.watch(authViewModelProvider);
    _onAuthStateChanged(authState);
  }

  void _onAuthStateChanged(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      final shelterID = authState.user?.shelterId;
      if (shelterID != null) {
        fetchAnimals(shelterID: shelterID);
      }
    } else {
      // Clear animals when not authenticated
      state = {'cats': [], 'dogs': []};
      _animalsSubscription?.cancel();
    }
  }

  // Add a field to store the main filter
  FilterElement? _enrichmentFilter;

  // Modify fetchAnimals to apply the filter
  void fetchAnimals({required String shelterID}) {
    _animalsSubscription?.cancel(); // Cancel any existing subscription

    // Fetch animals stream
    final animalsStream = _repository.fetchAnimals(shelterID);

    // Fetch account settings stream (filter)
    final accountSettingsStream = ref
        .watch(accountSettingsViewModelProvider.notifier)
        .stream
        .map((asyncValue) {
          return asyncValue.asData?.value;
        })
        .startWith(null); // Ensure the stream emits an initial value

    // Combine both streams
    _animalsSubscription =
        CombineLatestStream.combine2<List<Animal>, AppUser?, void>(
          animalsStream,
          accountSettingsStream,
          (animals, appUser) {
            _enrichmentFilter = appUser?.accountSettings?.visitorFilter;

            // Apply the filter
            final filteredAnimals = animals.where((animal) {
              if (_enrichmentFilter != null) {
                return evaluateFilter(_enrichmentFilter!, animal);
              } else {
                return true; // No filter applied
              }
            }).toList();

            final cats = filteredAnimals
                .where((animal) => animal.species == 'cat')
                .toList();
            final dogs = filteredAnimals
                .where((animal) => animal.species == 'dog')
                .toList();

            state = {'cats': cats, 'dogs': dogs};

            // Sort the animals after fetching and filtering
            _sortAnimals();
          },
        ).listen((_) {});
  }

  void _sortAnimals() {
    final accountSettings = ref
        .read(accountSettingsViewModelProvider)
        .asData
        ?.value;

    final visitorSort =
        accountSettings?.accountSettings?.visitorSort ?? 'Alphabetical';

    final sortedState = <String, List<Animal>>{};

    state.forEach((species, animalsList) {
      final sortedList = List<Animal>.from(animalsList);

      if (visitorSort == 'Alphabetical') {
        sortedList.sort((a, b) => a.name.compareTo(b.name));
      } else if (visitorSort == 'Intake Date') {
        sortedList.sort(
          (a, b) => (a.intakeDate ?? Timestamp(0, 0)).compareTo(
            b.intakeDate ?? Timestamp(0, 0),
          ),
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

    switch (condition.operatorType) {
      case OperatorType.equals:
        return attributeValue.toString().toLowerCase() ==
            conditionValue.toString().toLowerCase();
      case OperatorType.notEquals:
        return attributeValue.toString().toLowerCase() !=
            conditionValue.toString().toLowerCase();
      case OperatorType.contains:
        return attributeValue.toString().toLowerCase().contains(
          conditionValue.toString().toLowerCase(),
        );
      case OperatorType.notContains:
        return !attributeValue.toString().toLowerCase().contains(
          conditionValue.toString().toLowerCase(),
        );
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
      case 'letOutType':
        return animal.logs.map((log) => log.type.toLowerCase()).toList();
      case 'earlyPutBackReason':
        return animal.logs
            .where(
              (log) => log.earlyReason != null && log.earlyReason!.isNotEmpty,
            )
            .map((log) => log.earlyReason!.toLowerCase())
            .toList();
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

// Create a provider for the VisitorsViewModel
final visitorsViewModelProvider =
    StateNotifierProvider<VisitorsViewModel, Map<String, List<Animal>>>((ref) {
      final repository = ref.watch(
        visitorsRepositoryProvider,
      ); // Access the repository
      return VisitorsViewModel(repository, ref); // Pass the repository and ref
    });
