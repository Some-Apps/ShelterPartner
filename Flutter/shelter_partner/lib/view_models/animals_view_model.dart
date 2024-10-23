import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/animals_repository.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/device_settings_view_model.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';
import 'package:rxdart/rxdart.dart';

class AnimalsViewModel extends StateNotifier<Map<String, List<Animal>>> {
  final AnimalsRepository _repository;
  final Ref ref;

  StreamSubscription<void>? _animalsSubscription;

  AnimalsViewModel(this._repository, this.ref)
      : super({'cats': [], 'dogs': []}) {
    // Listen to authentication state changes
    ref.listen<AuthState>(
      authViewModelProvider,
      (previous, next) {
        _onAuthStateChanged(next);
      },
    );

    // Immediately check the current auth state
    final authState = ref.read(authViewModelProvider);
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
  FilterElement? _mainFilter;

  // Modify fetchAnimals to apply the filter
  void fetchAnimals({required String shelterID}) {
  _animalsSubscription?.cancel(); // Cancel any existing subscription

  // Fetch animals stream
  final animalsStream = _repository.fetchAnimals(shelterID);

  // Fetch device settings stream (filter)
  final deviceSettingsStream = ref
      .watch(deviceSettingsViewModelProvider.notifier)
      .stream
      .map((asyncValue) {
        return asyncValue.asData?.value;
      });

  // Combine both streams
  _animalsSubscription = CombineLatestStream.combine2<List<Animal>, AppUser?, void>(
    animalsStream,
    deviceSettingsStream,
    (animals, appUser) {
      _mainFilter = appUser?.deviceSettings.mainFilter;

      // Apply the filter
      final filteredAnimals = animals.where((animal) {
        if (_mainFilter != null) {
          return evaluateFilter(_mainFilter!, animal);
        } else {
          return true; // No filter applied
        }
      }).toList();

        final cats =
            filteredAnimals.where((animal) => animal.species == 'cat').toList();
        final dogs =
            filteredAnimals.where((animal) => animal.species == 'dog').toList();

        state = {'cats': cats, 'dogs': dogs};

        // Sort the animals after fetching and filtering
        _sortAnimals();
      },
    ).listen((_) {});
  }

  void _sortAnimals() {
    final deviceSettings =
        ref.read(deviceSettingsViewModelProvider).asData?.value;

    final mainSort = deviceSettings?.deviceSettings.mainSort ?? 'Alphabetical';

    final sortedState = <String, List<Animal>>{};

    state.forEach((species, animalsList) {
      final sortedList = List<Animal>.from(animalsList);

      if (mainSort == 'Alphabetical') {
        sortedList.sort((a, b) => a.name.compareTo(b.name));
      } else if (mainSort == 'Last Let Out') {
        sortedList
            .sort((a, b) => a.logs.last.endTime.compareTo(b.logs.last.endTime));
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
        return attributeValue
            .toString()
            .toLowerCase()
            .contains(conditionValue.toString().toLowerCase());
      case OperatorType.notContains:
        return !attributeValue
            .toString()
            .toLowerCase()
            .contains(conditionValue.toString().toLowerCase());
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
      default:
        return false;
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
      case 'age':
        return animal.age;
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

final animalsViewModelProvider =
    StateNotifierProvider<AnimalsViewModel, Map<String, List<Animal>>>((ref) {
  final repository =
      ref.watch(animalsRepositoryProvider); // Access the repository
  return AnimalsViewModel(repository, ref); // Pass the repository and ref
});
