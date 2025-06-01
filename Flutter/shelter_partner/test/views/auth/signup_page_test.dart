import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelter_partner/views/auth/signup_page.dart';
import 'package:shelter_partner/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

@GenerateMocks([AuthRepository, UserCredential, User])
import 'signup_page_test.mocks.dart';

void main() {
  group('SignupPage Widget Tests', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUserCredential.user).thenReturn(mockUser);
      when(
        mockAuthRepository.signUpWithEmailAndPassword(any, any),
      ).thenAnswer((_) async => mockUserCredential);
      when(
        mockAuthRepository.createUserDocument(
          uid: anyNamed('uid'),
          firstName: anyNamed('firstName'),
          lastName: anyNamed('lastName'),
          shelterId: anyNamed('shelterId'),
          email: anyNamed('email'),
          selectedManagementSoftware: anyNamed('selectedManagementSoftware'),
          shelterName: anyNamed('shelterName'),
          shelterAddress: anyNamed('shelterAddress'),
        ),
      ).thenAnswer((_) async => null);
      when(mockAuthRepository.getUserById(any)).thenAnswer((_) async => null);
    });

    Widget createTestWidget({void Function()? onTapLogin}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: MaterialApp(home: SignupPage(onTapLogin: onTapLogin ?? () {})),
      );
    }

    Finder emailField() => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Email',
    );
    Finder passwordField() => find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Password',
    );
    Finder confirmPasswordField() => find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Confirm Password',
    );
    Finder signupButton() =>
        find.widgetWithText(ElevatedButton, 'Create Shelter');

    testWidgets('should display all UI elements correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(emailField(), findsOneWidget);
      expect(passwordField(), findsOneWidget);
      expect(confirmPasswordField(), findsOneWidget);
      expect(signupButton(), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });

    testWidgets(
      'should call signup and createUserDocument when signup button tapped',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        // Fill all required fields for signup in the correct order
        await tester.enterText(
          find.byType(TextField).at(0),
          'First',
        ); // firstName
        await tester.enterText(
          find.byType(TextField).at(1),
          'Last',
        ); // lastName
        await tester.enterText(
          find.byType(TextField).at(2),
          'user@example.com',
        ); // email
        await tester.enterText(
          find.byType(TextField).at(3),
          'mypassword',
        ); // password
        await tester.enterText(
          find.byType(TextField).at(4),
          'mypassword',
        ); // confirm password
        await tester.enterText(
          find.byType(TextField).at(5),
          'Shelter Name',
        ); // shelterName
        await tester.enterText(
          find.byType(TextField).at(6),
          '123 Main St',
        ); // shelterAddress
        // Management software dropdown defaults to 'ShelterLuv', so no need to select unless testing other value
        await tester.tap(signupButton());
        await tester.pumpAndSettle();
        verify(
          mockAuthRepository.signUpWithEmailAndPassword(
            'user@example.com',
            'mypassword',
          ),
        ).called(1);
        verify(
          mockAuthRepository.createUserDocument(
            uid: 'test-uid',
            firstName: 'First',
            lastName: 'Last',
            shelterId: anyNamed('shelterId'), // generated in view model
            email: 'user@example.com',
            selectedManagementSoftware: 'ShelterLuv',
            shelterName: 'Shelter Name',
            shelterAddress: '123 Main St',
          ),
        ).called(1);
      },
    );

    testWidgets('should call onTapLogin when Login Here is tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      var tapped = false;
      await tester.pumpWidget(
        createTestWidget(onTapLogin: () => tapped = true),
      );
      await tester.pumpAndSettle();
      // Tap the "Login Here" text which is wrapped in a GestureDetector
      final loginHere = find.text('Login Here');
      await tester.tap(loginHere);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('should create account when pressing enter in last field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      // Fill all required fields for signup in the correct order
      await tester.enterText(
        find.byType(TextField).at(0),
        'First',
      ); // firstName
      await tester.enterText(find.byType(TextField).at(1), 'Last'); // lastName
      await tester.enterText(
        find.byType(TextField).at(2),
        'user@example.com',
      ); // email
      await tester.enterText(
        find.byType(TextField).at(3),
        'mypassword',
      ); // password
      await tester.enterText(
        find.byType(TextField).at(4),
        'mypassword',
      ); // confirm password
      await tester.enterText(
        find.byType(TextField).at(5),
        'Shelter Name',
      ); // shelterName
      await tester.enterText(
        find.byType(TextField).at(6),
        '123 Main St',
      ); // shelterAddress
      // Focus the last field and press enter
      await tester.showKeyboard(find.byType(TextField).at(6));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      verify(
        mockAuthRepository.signUpWithEmailAndPassword(
          'user@example.com',
          'mypassword',
        ),
      ).called(1);
      verify(
        mockAuthRepository.createUserDocument(
          uid: 'test-uid',
          firstName: 'First',
          lastName: 'Last',
          shelterId: anyNamed('shelterId'),
          email: 'user@example.com',
          selectedManagementSoftware: 'ShelterLuv',
          shelterName: 'Shelter Name',
          shelterAddress: '123 Main St',
        ),
      ).called(1);
    });
  });
}
