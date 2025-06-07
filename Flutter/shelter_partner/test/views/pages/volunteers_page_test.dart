import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelter_partner/views/pages/volunteers_page.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/repositories/volunteers_repository.dart';
import 'package:shelter_partner/view_models/volunteers_view_model.dart';

import '../../helpers/firebase_test_overrides.dart';
import '../../helpers/test_auth_helpers.dart';
import '../../helpers/test_volunteer_data.dart';

@GenerateMocks([VolunteersRepository])
import 'volunteers_page_test.mocks.dart';

void main() {
  group('VolunteersPage Widget Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('displays volunteer settings section and navigates to settings page', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'volunteersettingsuser@example.com',
        password: 'testpassword',
        firstName: 'VolunteerSettings',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      // Mock router to track navigation
      String? navigatedRoute;
      final router = GoRouter(
        initialLocation: '/volunteers',
        routes: [
          GoRoute(
            path: '/volunteers',
            builder: (context, state) => const VolunteersPage(),
          ),
          GoRoute(
            path: '/volunteers/volunteer-settings',
            builder: (context, state) {
              navigatedRoute = '/volunteers/volunteer-settings';
              return const Scaffold(
                body: Text('Volunteer Settings Page'),
              );
            },
          ),
        ],
      );

      // Act: Build the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Check that volunteer settings section is present
      expect(find.text('Volunteer Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Act: Tap on volunteer settings
      final volunteerSettingsTile = find.widgetWithText(ListTile, 'Volunteer Settings');
      expect(volunteerSettingsTile, findsOneWidget);
      await tester.tap(volunteerSettingsTile);
      await tester.pumpAndSettle();

      // Assert: Navigation occurred
      expect(navigatedRoute, equals('/volunteers/volunteer-settings'));
    });

    testWidgets('displays invite volunteer form with validation', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'invitevolunteeruser@example.com',
        password: 'testpassword',
        firstName: 'InviteVolunteer',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      // Act: Build the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteersPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Check that invite volunteer section is present
      expect(find.text('Invite a Volunteer'), findsOneWidget);
      expect(find.text('Volunteer first name'), findsOneWidget);
      expect(find.text('Volunteer last name'), findsOneWidget);
      expect(find.text('Volunteer email'), findsOneWidget);
      expect(find.text('Send Invite'), findsOneWidget);

      // Test form validation - try to submit empty form
      final sendInviteButton = find.widgetWithText(ElevatedButton, 'Send Invite');
      await tester.tap(sendInviteButton);
      await tester.pumpAndSettle();

      // Assert: Validation errors should appear
      expect(find.text('Please enter the volunteer\'s first name'), findsOneWidget);
      expect(find.text('Please enter the volunteer\'s last name'), findsOneWidget);
      expect(find.text('Please enter the volunteer email'), findsOneWidget);
    });

    testWidgets('invite volunteer form validates email format', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'emailvalidationuser@example.com',
        password: 'testpassword',
        firstName: 'EmailValidation',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      // Act: Build the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteersPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in form with invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Volunteer first name'),
        'Jane',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Volunteer last name'),
        'Smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Volunteer email'),
        'invalid-email',
      );

      // Try to submit form
      final sendInviteButton = find.widgetWithText(ElevatedButton, 'Send Invite');
      await tester.tap(sendInviteButton);
      await tester.pumpAndSettle();

      // Assert: Email validation error should appear
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('displays volunteers list when volunteers exist', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'volunteerslistuser@example.com',
        password: 'testpassword',
        firstName: 'VolunteersList',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';

      // Add test volunteers to Firestore in the 'users' collection
      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc('volunteer1')
          .set(createTestVolunteerData(
            id: 'volunteer1',
            firstName: 'Alice',
            lastName: 'Johnson',
            email: 'alice.johnson@example.com',
            shelterID: shelterId,
          ));

      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc('volunteer2')
          .set(createTestVolunteerData(
            id: 'volunteer2',
            firstName: 'Bob',
            lastName: 'Wilson',
            email: 'bob.wilson@example.com',
            shelterID: shelterId,
          ));

      // Act: Build the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteersPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Check that volunteers section is present
      expect(find.text('Volunteers'), findsOneWidget);
      expect(find.text('Search Volunteers'), findsOneWidget);

      // Check that volunteers are displayed
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);
      
      // Check that delete buttons are present in the volunteers list
      // Find delete buttons within ListTile widgets that have volunteer names
      final aliceListTile = find.ancestor(
        of: find.text('Alice Johnson'),
        matching: find.byType(ListTile),
      );
      final bobListTile = find.ancestor(
        of: find.text('Bob Wilson'),
        matching: find.byType(ListTile),
      );
      
      expect(find.descendant(
        of: aliceListTile,
        matching: find.byIcon(Icons.delete),
      ), findsOneWidget);
      expect(find.descendant(
        of: bobListTile,
        matching: find.byIcon(Icons.delete),
      ), findsOneWidget);
      
      // Check that sort dropdown is present
      expect(find.text('A-Z'), findsOneWidget);
    });

    testWidgets('search functionality filters volunteers', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'searchvolunteersuser@example.com',
        password: 'testpassword',
        firstName: 'SearchVolunteers',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';

      // Add test volunteers to Firestore in the 'users' collection
      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc('volunteer1')
          .set(createTestVolunteerData(
            id: 'volunteer1',
            firstName: 'Alice',
            lastName: 'Johnson',
            email: 'alice.johnson@example.com',
            shelterID: shelterId,
          ));

      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc('volunteer2')
          .set(createTestVolunteerData(
            id: 'volunteer2',
            firstName: 'Bob',
            lastName: 'Wilson',
            email: 'bob.wilson@example.com',
            shelterID: shelterId,
          ));

      await FirebaseTestOverrides.fakeFirestore
          .collection('users')
          .doc('volunteer3')
          .set(createTestVolunteerData(
            id: 'volunteer3',
            firstName: 'Charlie',
            lastName: 'Brown',
            email: 'charlie.brown@example.com',
            shelterID: shelterId,
          ));

      // Act: Build the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteersPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Precondition: All volunteers are visible
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);
      expect(find.text('Charlie Brown'), findsOneWidget);

      // Act: Search for "Alice"
      final searchField = find.widgetWithText(TextField, 'Search Volunteers');
      await tester.enterText(searchField, 'Alice');
      await tester.pumpAndSettle();

      // Assert: Only Alice should be visible
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsNothing);
      expect(find.text('Charlie Brown'), findsNothing);

      // Act: Search for "Brown"
      await tester.enterText(searchField, 'Brown');
      await tester.pumpAndSettle();

      // Assert: Only Charlie should be visible
      expect(find.text('Alice Johnson'), findsNothing);
      expect(find.text('Bob Wilson'), findsNothing);
      expect(find.text('Charlie Brown'), findsOneWidget);

      // Act: Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Assert: All volunteers should be visible again
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);
      expect(find.text('Charlie Brown'), findsOneWidget);
    });

    testWidgets('shows volunteer list with admin user when no additional volunteers exist', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter (admin user will appear as volunteer)
      final container = await createTestUserAndLogin(
        email: 'onlyadminuser@example.com',
        password: 'testpassword',
        firstName: 'OnlyAdmin',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      // Act: Build the widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteersPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Check that admin user appears in volunteers section
      expect(find.text('Volunteers'), findsOneWidget);
      expect(find.text('Search Volunteers'), findsOneWidget);
      expect(find.text('OnlyAdmin Tester'), findsOneWidget);
      
      // The "No volunteers available" message should NOT appear since admin is a volunteer
      expect(find.text('No volunteers available at the moment'), findsNothing);
    });

    testWidgets('successfully sends volunteer invite when form is submitted with valid data', (
      WidgetTester tester,
    ) async {
      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'invitesuccessuser@example.com',
        password: 'testpassword',
        firstName: 'InviteSuccess',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';

      // Create mock repository and set up successful response
      final mockRepository = MockVolunteersRepository();
      when(mockRepository.sendVolunteerInvite(
        any,
        any,
        any,
        any,
      )).thenAnswer((_) async {});

      // Mock the fetchShelterWithVolunteers to return a shelter with the admin user
      // This ensures the widget displays correctly while we test the invite functionality
      when(mockRepository.fetchShelterWithVolunteers(any))
          .thenAnswer((_) => Stream.value(
                createTestShelterWithVolunteers(
                  shelterId: shelterId,
                  volunteers: [
                    createTestVolunteer(
                      id: 'admin-user',
                      firstName: 'InviteSuccess',
                      lastName: 'Tester',
                      email: 'invitesuccessuser@example.com',
                      shelterID: shelterId,
                    ),
                  ],
                ),
              ));

      // Act: Build the widget with mocked repository
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...FirebaseTestOverrides.overrides,
            authViewModelProvider.overrideWith((ref) =>
                container.read(authViewModelProvider.notifier)),
            volunteersRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(home: VolunteersPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in the form with valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Volunteer first name'),
        'Jane',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Volunteer last name'),
        'Smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Volunteer email'),
        'jane.smith@example.com',
      );

      // Act: Submit the form
      final sendInviteButton = find.widgetWithText(ElevatedButton, 'Send Invite');
      await tester.tap(sendInviteButton);
      await tester.pumpAndSettle();

      // Assert: Verify that the repository method was called with correct parameters
      verify(mockRepository.sendVolunteerInvite(
        'Jane',
        'Smith',
        'jane.smith@example.com',
        shelterId,
      )).called(1);

      // Assert: Verify success snackbar is shown
      expect(find.text('Invite sent successfully'), findsOneWidget);

      // Assert: Verify form fields are cleared after successful submission
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Volunteer first name'),
        ).controller?.text,
        isEmpty,
      );
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Volunteer last name'),
        ).controller?.text,
        isEmpty,
      );
      expect(
        tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Volunteer email'),
        ).controller?.text,
        isEmpty,
      );
    });

    testWidgets('successfully deletes volunteer when delete button is tapped and confirmed', (
      WidgetTester tester,
    ) async {
      // Set a larger screen size for this test
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Arrange: Create test user and shelter
      final container = await createTestUserAndLogin(
        email: 'deletevolunteeruser@example.com',
        password: 'testpassword',
        firstName: 'DeleteVolunteer',
        lastName: 'Tester',
        shelterName: 'Test Shelter',
        shelterAddress: '123 Test St',
        selectedManagementSoftware: 'ShelterLuv',
      );

      final user = container.read(appUserProvider);
      final shelterId = user?.shelterId ?? 'test-shelter';

      // Create mock repository and set up successful response
      final mockRepository = MockVolunteersRepository();
      when(mockRepository.deleteVolunteer(
        any,
        any,
      )).thenAnswer((_) async {});

      // Mock the fetchShelterWithVolunteers to return a shelter with volunteers including Alice
      when(mockRepository.fetchShelterWithVolunteers(any))
          .thenAnswer((_) => Stream.value(
                createTestShelterWithVolunteers(
                  shelterId: shelterId,
                  volunteers: [
                    createTestVolunteer(
                      id: 'admin-user',
                      firstName: 'DeleteVolunteer',
                      lastName: 'Tester',
                      email: 'deletevolunteeruser@example.com',
                      shelterID: shelterId,
                    ),
                    createTestVolunteer(
                      id: 'volunteer-to-delete',
                      firstName: 'Alice',
                      lastName: 'Johnson',
                      email: 'alice.johnson@example.com',
                      shelterID: shelterId,
                    ),
                  ],
                ),
              ));

      // Act: Build the widget with mocked repository
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...FirebaseTestOverrides.overrides,
            authViewModelProvider.overrideWith((ref) =>
                container.read(authViewModelProvider.notifier)),
            volunteersRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(home: VolunteersPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify volunteer is displayed
      expect(find.text('Alice Johnson'), findsOneWidget);

      // Find the delete button for Alice Johnson
      final aliceListTile = find.ancestor(
        of: find.text('Alice Johnson'),
        matching: find.byType(ListTile),
      );
      final deleteButton = find.descendant(
        of: aliceListTile,
        matching: find.byIcon(Icons.delete),
      );
      expect(deleteButton, findsOneWidget);

      // Act: Tap the delete button
      await tester.tap(deleteButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert: Verify confirmation dialog is shown
      expect(find.text('Confirm Deletion'), findsOneWidget);
      expect(find.text('Are you sure you want to delete Alice?'), findsOneWidget);

      // Act: Confirm deletion
      final deleteConfirmButton = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(deleteConfirmButton);
      await tester.pumpAndSettle();

      // Assert: Verify that the repository delete method was called with correct parameters
      verify(mockRepository.deleteVolunteer(
        'volunteer-to-delete',
        shelterId,
      )).called(1);

      // Assert: Verify success snackbar is shown
      expect(find.text('Alice deleted'), findsOneWidget);
    });
  });
}