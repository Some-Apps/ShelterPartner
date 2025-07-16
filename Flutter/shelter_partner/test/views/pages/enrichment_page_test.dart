import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/pages/enrichment_page.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/views/components/animal_card_view.dart';
import 'package:shelter_partner/views/components/simplistic_animal_card_view.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_animal_data.dart';
import '../../helpers/test_auth_helpers.dart';

// === Test Helpers ===
Finder findAdditionalOptionsTile() =>
    find.widgetWithText(ExpansionTile, 'Additional Options');
Finder findAttributeDropdown(String value) => find.byWidgetPredicate(
  (w) => w is DropdownButton<String> && w.value == value,
);
Finder findLocationTierDropdown() =>
    find.byWidgetPredicate((w) => w is DropdownButton<int>);
Finder findGroupByDropdown(String value) => find.byWidgetPredicate(
  (w) => w is DropdownButton<String> && w.value == value,
);
Finder findSectionHeader(String sectionTitle) =>
    find.byKey(ValueKey('sectionHeader_$sectionTitle'));
Finder findSearchField() => find.byType(TextField).first;

bool isAnimalCardText(Element element, String name) {
  final widget = element.widget;
  if (widget is Text && widget.data == name) {
    bool found = false;
    element.visitAncestorElements((ancestor) {
      final typeStr = ancestor.widget.runtimeType.toString();
      if (typeStr.contains('AnimalCardView') ||
          typeStr.contains('SimplisticAnimalCardView')) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }
  return false;
}

int countAnimalCardText(String name) {
  return find
      .byWidgetPredicate((widget) => widget is Text && widget.data == name)
      .evaluate()
      .where((element) => isAnimalCardText(element, name))
      .length;
}

void main() {
  group('EnrichmentPage Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('displays animals in the list/grid', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter, get shared container
      final container = await createTestUserAndLogin(
        email: 'enrichmentuser@example.com',
        password: 'testpassword',
        firstName: 'Enrichment',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      // Get the correct shelterId from the logged-in user
      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';
      // Add test animals to Firestore using the correct shelterId
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog1')
          .set(createTestAnimalData(id: 'dog1', name: 'Sammy'));
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: EnrichmentPage()),
        ),
      );
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Buddy'), findsOneWidget); // from default test data
      expect(find.text('Max'), findsOneWidget); // from default test data
      expect(find.text('Sammy'), findsOneWidget);
    });

    testWidgets(
      'search bar should filter visible animals by the entered query and selected attribute',
      (WidgetTester tester) async {
        // Arrange: Create test user and shelter, get shared container
        final container = await createTestUserAndLogin(
          email: 'searchbaruser@example.com',
          password: 'testpassword',
          firstName: 'Search',
          lastName: 'Tester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
        final user = container.read(appUserProvider);
        final shelterId = user?.shelterId ?? 'test-shelter';
        // Add test animals
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog1')
            .set(createTestAnimalData(id: 'dog1', name: 'Sammy'));
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog2')
            .set(createTestAnimalData(id: 'dog2', name: 'Rex'));
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog3')
            .set(createTestAnimalData(id: 'dog3', name: 'Charlie'));
        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: EnrichmentPage()),
          ),
        );
        await tester.pumpAndSettle();
        // Precondition: All animals are visible
        expect(find.text('Sammy'), findsOneWidget);
        expect(find.text('Rex'), findsOneWidget);
        expect(find.text('Charlie'), findsOneWidget);
        // Open the Additional Options expansion tile to reveal the search bar
        final additionalOptionsTile = findAdditionalOptionsTile();
        expect(additionalOptionsTile, findsOneWidget);
        await tester.tap(additionalOptionsTile);
        await tester.pumpAndSettle();
        // Now find the search bar and enter a query
        final searchField = findSearchField();
        await tester.enterText(searchField, 'Sammy');
        await tester.pumpAndSettle();
        // Only Sammy should be visible
        expect(countAnimalCardText('Sammy'), 1);
        expect(countAnimalCardText('Rex'), 0);
        expect(countAnimalCardText('Charlie'), 0);
        // Clear the search and search for 'Rex'
        await tester.enterText(searchField, 'Rex');
        await tester.pumpAndSettle();
        expect(countAnimalCardText('Sammy'), 0);
        expect(countAnimalCardText('Rex'), 1);
        expect(countAnimalCardText('Charlie'), 0);
        // Search for a name that doesn't exist
        await tester.enterText(searchField, 'NotARealDog');
        await tester.pumpAndSettle();
        expect(countAnimalCardText('Sammy'), 0);
        expect(countAnimalCardText('Rex'), 0);
        expect(countAnimalCardText('Charlie'), 0);
      },
    );

    testWidgets(
      'attribute dropdown should change which animal property is searched',
      (WidgetTester tester) async {
        // Arrange: Create test user and shelter, get shared container
        final container = await createTestUserAndLogin(
          email: 'attributedropdownuser@example.com',
          password: 'testpassword',
          firstName: 'Attribute',
          lastName: 'Tester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
        final user = container.read(appUserProvider);
        final shelterId = user?.shelterId ?? 'test-shelter';
        // Add test animals with different breeds
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog1')
            .set(
              createTestAnimalData(
                id: 'dog1',
                name: 'Sammy',
                breed: 'Labrador',
              ),
            );
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog2')
            .set(
              createTestAnimalData(id: 'dog2', name: 'Rex', breed: 'Poodle'),
            );
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog3')
            .set(
              createTestAnimalData(
                id: 'dog3',
                name: 'Charlie',
                breed: 'Beagle',
              ),
            );
        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: EnrichmentPage()),
          ),
        );
        await tester.pumpAndSettle();
        // Open the Additional Options expansion tile to reveal the dropdowns
        final additionalOptionsTile = findAdditionalOptionsTile();
        expect(additionalOptionsTile, findsOneWidget);
        await tester.tap(additionalOptionsTile);
        await tester.pumpAndSettle();
        // Find the attribute dropdown and change it to 'Breed'
        final attributeDropdown = findAttributeDropdown('Name');
        expect(attributeDropdown, findsOneWidget);
        await tester.tap(attributeDropdown);
        await tester.pumpAndSettle();
        final breedItem = find.text('Breed').last;
        await tester.tap(breedItem);
        await tester.pumpAndSettle();
        // Find the search bar and enter a breed query
        final searchField = findSearchField();
        await tester.enterText(searchField, 'Poodle');
        await tester.pumpAndSettle();
        // Only Rex (breed: Poodle) should be visible
        expect(countAnimalCardText('Sammy'), 0);
        expect(countAnimalCardText('Rex'), 1);
        expect(countAnimalCardText('Charlie'), 0);
        // Change search to 'Beagle'
        await tester.enterText(searchField, 'Beagle');
        await tester.pumpAndSettle();
        expect(countAnimalCardText('Sammy'), 0);
        expect(countAnimalCardText('Rex'), 0);
        expect(countAnimalCardText('Charlie'), 1);
      },
    );

    testWidgets(
      'location tier dropdown should update the number of location tiers shown on animal cards',
      (WidgetTester tester) async {
        // Arrange: Create test user and shelter, get shared container
        final container = await createTestUserAndLogin(
          email: 'locationtieruser@example.com',
          password: 'testpassword',
          firstName: 'Location',
          lastName: 'TierTester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
        final user = container.read(appUserProvider);
        final shelterId = user?.shelterId ?? 'test-shelter';
        // Add a test animal with a multi-tier location
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog1')
            .set(
              createTestAnimalData(
                id: 'dog1',
                name: 'Sammy',
                location: 'Building A > Floor 2 > Room 5 > Kennel 12',
              ),
            );
        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: EnrichmentPage()),
          ),
        );
        await tester.pumpAndSettle();
        // Open the Additional Options expansion tile to reveal the dropdowns
        final additionalOptionsTile = findAdditionalOptionsTile();
        expect(additionalOptionsTile, findsOneWidget);
        await tester.tap(additionalOptionsTile);
        await tester.pumpAndSettle();
        // Find the location tier dropdown and change it to 2
        final locationTierDropdown = findLocationTierDropdown();
        expect(locationTierDropdown, findsOneWidget);
        await tester.tap(locationTierDropdown);
        await tester.pumpAndSettle();
        final twoTiers = find.textContaining('2 tier').last;
        await tester.tap(twoTiers);
        await tester.pumpAndSettle();
        // The animal card should now show only the last 2 tiers: 'Room 5 > Kennel 12'
        expect(find.textContaining('Room 5 > Kennel 12'), findsOneWidget);
        // Change to 4 tiers
        await tester.tap(locationTierDropdown);
        await tester.pumpAndSettle();
        final fourTiers = find.textContaining('4 tier').last;
        await tester.tap(fourTiers);
        await tester.pumpAndSettle();
        // The animal card should now show all 4 tiers: 'Building A > Floor 2 > Room 5 > Kennel 12'
        expect(
          find.textContaining('Building A > Floor 2 > Room 5 > Kennel 12'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'group by dropdown should group animals by the selected category',
      (WidgetTester tester) async {
        // Arrange: Create test user and shelter, get shared container
        final container = await createTestUserAndLogin(
          email: 'groupbyuser@example.com',
          password: 'testpassword',
          firstName: 'Group',
          lastName: 'ByTester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
        final user = container.read(appUserProvider);
        final shelterId = user?.shelterId ?? 'test-shelter';
        // Add test animals with different adoption categories
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog1')
            .set(
              createTestAnimalData(
                id: 'dog1',
                name: 'Sammy',
                adoptionCategory: 'Puppy',
              ),
            );
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog2')
            .set(
              createTestAnimalData(
                id: 'dog2',
                name: 'Rex',
                adoptionCategory: 'Adult',
              ),
            );
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog3')
            .set(
              createTestAnimalData(
                id: 'dog3',
                name: 'Charlie',
                adoptionCategory: 'Puppy',
              ),
            );
        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: EnrichmentPage()),
          ),
        );
        await tester.pumpAndSettle();
        // Open the Additional Options expansion tile to reveal the dropdowns
        final additionalOptionsTile = findAdditionalOptionsTile();
        expect(
          additionalOptionsTile,
          findsOneWidget,
          reason: "additional options not found",
        );
        await tester.tap(additionalOptionsTile);
        await tester.pumpAndSettle();
        // Find the group by dropdown and change it to 'Adoption Category'
        final groupByDropdown = findGroupByDropdown('None');
        expect(
          groupByDropdown,
          findsOneWidget,
          reason: "group by dropdown not found",
        );
        await tester.tap(groupByDropdown);
        await tester.pumpAndSettle();
        final adoptionCategoryItem = find.text('Adoption Category').last;
        await tester.tap(adoptionCategoryItem);
        await tester.pumpAndSettle();
        // Reacquire the ExpansionTile finder before collapsing
        final additionalOptionsTileCollapsed = find.widgetWithText(
          ExpansionTile,
          'Additional Options',
        );
        expect(additionalOptionsTileCollapsed, findsOneWidget);
        // Find the ListTile inside the ExpansionTile and tap it to collapse
        final headerTile = find.descendant(
          of: additionalOptionsTileCollapsed,
          matching: find.byType(ListTile),
        );
        await tester.tap(headerTile.first);
        await tester.pumpAndSettle();
        // Find the ListView containing the section headers
        final listViewFinder = find.byType(ListView).first;
        // Find the first Scrollable descendant of the ListView
        final scrollableFinder = find
            .descendant(of: listViewFinder, matching: find.byType(Scrollable))
            .first;
        // Scroll until section headers are visible before asserting
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('sectionHeader_Puppy')),
          200.0,
          scrollable: scrollableFinder,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('sectionHeader_Adult')),
          200.0,
          scrollable: scrollableFinder,
        );

        expect(findSectionHeader('Puppy'), findsOneWidget);
        expect(findSectionHeader('Adult'), findsOneWidget);
        // Change group by to None
        // Re-expand the Additional Options expansion tile before changing the dropdown
        await tester.tap(additionalOptionsTile);
        await tester.pumpAndSettle();
        // Re-acquire the groupByDropdown finder before tapping
        final groupByDropdownCurrent = findGroupByDropdown('Adoption Category');
        expect(
          groupByDropdownCurrent,
          findsOneWidget,
          reason: "group by dropdown not found after re-expanding",
        );
        await tester.tap(groupByDropdownCurrent);
        await tester.pumpAndSettle();
        await tester.tap(find.text('None').last);
        await tester.pumpAndSettle();
        expect(findSectionHeader('Puppy'), findsNothing);
        expect(findSectionHeader('Adult'), findsNothing);
      },
    );

    testWidgets(
      'simplistic mode toggle should update the UI between simplistic and detailed modes',
      (WidgetTester tester) async {
        // Arrange: Create test user and shelter, get shared container
        final container = await createTestUserAndLogin(
          email: 'simplisticmodeuser@example.com',
          password: 'testpassword',
          firstName: 'Simple',
          lastName: 'ModeTester',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
        final user = container.read(appUserProvider);
        final shelterId = user?.shelterId ?? 'test-shelter';
        // Add a test animal
        await FirebaseTestOverrides.fakeFirestore
            .collection('shelters')
            .doc(shelterId)
            .collection('dogs')
            .doc('dog1')
            .set(createTestAnimalData(id: 'dog1', name: 'Sammy'));
        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: EnrichmentPage()),
          ),
        );
        await tester.pumpAndSettle();
        // Open the Additional Options expansion tile to reveal the simplistic mode toggle
        final additionalOptionsTile = findAdditionalOptionsTile();
        expect(additionalOptionsTile, findsOneWidget);
        await tester.tap(additionalOptionsTile);
        await tester.pumpAndSettle();
        // Find the simplistic mode switch
        final simplisticSwitch = find.byType(Switch).first;
        expect(
          simplisticSwitch,
          findsOneWidget,
          reason: 'Simplistic mode switch should be present',
        );
        // By default, simplistic mode should be shown (SimplisticAnimalCardView)
        expect(
          find.byType(SimplisticAnimalCardView),
          findsWidgets,
          reason:
              'SimplisticAnimalCardView widgets should be present in simplistic mode by default',
        );
        // Toggle the switch to enable detailed mode
        await tester.tap(simplisticSwitch);
        await tester.pumpAndSettle();
        // Now, AnimalCardView should be shown
        expect(
          find.byType(AnimalCardView),
          findsWidgets,
          reason:
              'AnimalCardView widgets should be present after toggling to detailed mode',
        );
        // Confirm that the user's account settings are updated
        final settings = container
            .read(accountSettingsViewModelProvider)
            .value
            ?.accountSettings;
        expect(
          settings?.simplisticMode,
          isFalse,
          reason:
              'Account settings should reflect simplistic mode as disabled after toggling',
        );
        // Toggle back to simplistic mode
        await tester.tap(simplisticSwitch);
        await tester.pumpAndSettle();
        expect(
          find.byType(SimplisticAnimalCardView),
          findsWidgets,
          reason:
              'SimplisticAnimalCardView widgets should be present after toggling back to simplistic mode',
        );
        final settingsAfter = container
            .read(accountSettingsViewModelProvider)
            .value
            ?.accountSettings;
        expect(
          settingsAfter?.simplisticMode,
          isTrue,
          reason:
              'Account settings should reflect simplistic mode as enabled after toggling back',
        );
      },
    );

    testWidgets('applies user filter to animal list', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user with a specific user filter
      final container = await createTestUserAndLogin(
        email: 'filterapplyuser@example.com',
        password: 'testpassword',
        firstName: 'FilterApply',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';

      // Add test animals with different names and breeds
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog1')
          .set(
            createTestAnimalData(
              id: 'dog1',
              name: 'Filtered Dog',
              breed: 'Labrador',
            ),
          );

      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog2')
          .set(
            createTestAnimalData(
              id: 'dog2',
              name: 'Another Dog',
              breed: 'Poodle',
            ),
          );

      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog3')
          .set(
            createTestAnimalData(
              id: 'dog3',
              name: 'Third Dog',
              breed: 'Beagle',
            ),
          );

      // Create a user filter that filters for name containing "Filtered"
      final userFilterData = {
        'filterElements': [
          {
            'type': 'condition',
            'attribute': 'name',
            'operatorType': 'contains',
            'value': 'Filtered',
          },
        ],
        'operatorsBetween': {},
      };

      // Update the user document with the filter
      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc(user!.id)
          .update({'userFilter': userFilterData});

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: EnrichmentPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Only the filtered dog should be visible
      expect(find.text('Filtered Dog'), findsOneWidget);
      expect(find.text('Another Dog'), findsNothing);
      expect(find.text('Third Dog'), findsNothing);
    });

    testWidgets('user filter works together with search functionality', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user
      final container = await createTestUserAndLogin(
        email: 'combinedfilteruser@example.com',
        password: 'testpassword',
        firstName: 'CombinedFilter',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';

      // Add test animals - use names that contain common letters
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog1')
          .set(
            createTestAnimalData(
              id: 'dog1',
              name: 'Cooper Dog',
              breed: 'Labrador',
            ),
          );

      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog2')
          .set(
            createTestAnimalData(
              id: 'dog2',
              name: 'Riley Dog',
              breed: 'Poodle',
            ),
          );

      // Create a user filter that filters for name containing "Dog" (which all our test animals should have)
      final userFilterData = {
        'filterElements': [
          {
            'type': 'condition',
            'attribute': 'name',
            'operatorType': 'contains',
            'value': 'Dog',
          },
        ],
        'operatorsBetween': {},
      };

      // Update the user document with the filter
      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc(user!.id)
          .update({'userFilter': userFilterData});

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: EnrichmentPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Now also use search functionality to further filter by breed
      // Open the Additional Options to access the search attribute dropdown
      final additionalOptionsTile = findAdditionalOptionsTile();
      expect(additionalOptionsTile, findsOneWidget);
      await tester.tap(additionalOptionsTile);
      await tester.pumpAndSettle();

      // Change the search attribute to 'Breed'
      final attributeDropdown = findAttributeDropdown('Name');
      expect(attributeDropdown, findsOneWidget);
      await tester.tap(attributeDropdown);
      await tester.pumpAndSettle();
      final breedItem = find.text('Breed').last;
      await tester.tap(breedItem);
      await tester.pumpAndSettle();

      // Use search to filter by 'Labrador' breed
      final searchField = findSearchField();
      await tester.enterText(searchField, 'Labrador');
      await tester.pumpAndSettle();

      // Assert: Only Cooper Dog should be visible (has "Dog" in name AND is a Labrador)
      expect(find.text('Cooper Dog'), findsOneWidget);
      expect(
        find.text('Riley Dog'),
        findsNothing,
      ); // Riley is a Poodle, not Labrador

      // The default test animals (Buddy, Max) should NOT be visible since they don't contain "Dog"
      expect(find.text('Buddy'), findsNothing);
      expect(find.text('Max'), findsNothing);
    });

    testWidgets('search bar should support Let Out Type and Early Put Back Reasons attributes', (WidgetTester tester) async {
      // Arrange: Create test user and shelter, get shared container
      final container = await createTestUserAndLogin(
        email: 'logsearchuser@example.com',
        password: 'testpassword',
        firstName: 'LogSearch',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );
      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';
      
      // Add test animals with logs containing different types and early reasons
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog1')
          .set(createTestAnimalData(
            id: 'dog1', 
            name: 'Sammy',
            logs: [
              {
                'id': 'log1',
                'type': 'Walk',
                'author': 'Volunteer',
                'authorID': 'vol1',
                'startTime': DateTime.now().subtract(const Duration(hours: 2)),
                'endTime': DateTime.now().subtract(const Duration(hours: 1)),
                'earlyReason': null,
              },
              {
                'id': 'log2',
                'type': 'Training',
                'author': 'Volunteer',
                'authorID': 'vol1',
                'startTime': DateTime.now().subtract(const Duration(hours: 4)),
                'endTime': DateTime.now().subtract(const Duration(hours: 3)),
                'earlyReason': 'Medical attention needed',
              }
            ]
          ));
      
      await FirebaseTestOverrides.fakeFirestore
          .collection('shelters')
          .doc(shelterId)
          .collection('dogs')
          .doc('dog2')
          .set(createTestAnimalData(
            id: 'dog2', 
            name: 'Rex',
            logs: [
              {
                'id': 'log3',
                'type': 'Playtime',
                'author': 'Volunteer',
                'authorID': 'vol2',
                'startTime': DateTime.now().subtract(const Duration(hours: 1)),
                'endTime': DateTime.now(),
                'earlyReason': null,
              }
            ]
          ));

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: EnrichmentPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Open the Additional Options expansion tile to reveal the dropdowns
      final additionalOptionsTile = findAdditionalOptionsTile();
      expect(additionalOptionsTile, findsOneWidget);
      await tester.tap(additionalOptionsTile);
      await tester.pumpAndSettle();

      // Test Let Out Type search
      // Find the attribute dropdown and select "Let Out Type"
      final attributeDropdown = findAttributeDropdown('Name');
      expect(attributeDropdown, findsOneWidget);
      await tester.tap(attributeDropdown);
      await tester.pumpAndSettle();

      // Verify "Let Out Type" option is available
      expect(find.text('Let Out Type'), findsOneWidget);
      await tester.tap(find.text('Let Out Type'));
      await tester.pumpAndSettle();

      // Search for 'Walk' in let out types
      final searchField = findSearchField();
      await tester.enterText(searchField, 'Walk');
      await tester.pumpAndSettle();

      // Only Sammy should be visible (has a log with type 'Walk')
      expect(countAnimalCardText('Sammy'), 1);
      expect(countAnimalCardText('Rex'), 0);

      // Test Early Put Back Reasons search
      // Change to Early Put Back Reasons attribute
      await tester.tap(attributeDropdown);
      await tester.pumpAndSettle();
      
      // Verify "Early Put Back Reasons" option is available
      expect(find.text('Early Put Back Reasons'), findsOneWidget);
      await tester.tap(find.text('Early Put Back Reasons'));
      await tester.pumpAndSettle();

      // Clear previous search and search for 'Medical'
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Medical');
      await tester.pumpAndSettle();

      // Only Sammy should be visible (has a log with early reason containing 'Medical')
      expect(countAnimalCardText('Sammy'), 1);
      expect(countAnimalCardText('Rex'), 0);

      // Search for something that doesn't exist
      await tester.enterText(searchField, 'Nonexistent');
      await tester.pumpAndSettle();

      // No animals should be visible
      expect(countAnimalCardText('Sammy'), 0);
      expect(countAnimalCardText('Rex'), 0);
    });
  });
}
