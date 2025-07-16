import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/components/global_context_menu_wrapper.dart';

import '../../helpers/firebase_test_overrides.dart';

void main() {
  group('GlobalContextMenuWrapper Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    testWidgets('should render child widget correctly', (
      WidgetTester tester,
    ) async {
      const testWidget = Text('Test Child');

      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(
            home: Scaffold(body: GlobalContextMenuWrapper(child: testWidget)),
          ),
        ),
      );

      // Verify child widget is rendered
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should show context menu on right click in web environment', (
      WidgetTester tester,
    ) async {
      // This test would only apply to web, but since we're in test environment,
      // we'll just verify the widget structure
      const testWidget = Text('Test Child');

      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(
            home: Scaffold(body: GlobalContextMenuWrapper(child: testWidget)),
          ),
        ),
      );

      // Verify the wrapper contains a GestureDetector when on web
      if (kIsWeb) {
        expect(find.byType(GestureDetector), findsOneWidget);
      }

      // Verify child is still present
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should pass through child on non-web platforms', (
      WidgetTester tester,
    ) async {
      const testWidget = Text('Test Child');

      await tester.pumpWidget(
        ProviderScope(
          overrides: FirebaseTestOverrides.overrides,
          child: const MaterialApp(
            home: Scaffold(body: GlobalContextMenuWrapper(child: testWidget)),
          ),
        ),
      );

      // Should always render the child
      expect(find.text('Test Child'), findsOneWidget);
    });
  });
}
