import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/views/auth/signup_page.dart';
import 'package:shelter_partner/helper/debug.dart';

void main() {
  testWidgets('Create Test Account button is not visible in release mode',
      (WidgetTester tester) async {
    final debugHelper = DebugHelper(debugMode: false);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: SignupPage(onTapLogin: () {}, debugHelper: debugHelper),
      ),
    ));

    expect(find.text('Create Test Account'), findsNothing);
  });

  testWidgets('Create Test Account button is visible in debug mode',
      (WidgetTester tester) async {
    final debugHelper = DebugHelper(debugMode: true);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: SignupPage(onTapLogin: () {}, debugHelper: debugHelper),
      ),
    ));

    expect(find.text('Create Test Account'), findsOneWidget);
  });
}
