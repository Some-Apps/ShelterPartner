import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/models/tag.dart';
import 'package:shelter_partner/views/components/tags_view.dart';

void main() {
  group('TagsWidget Tests', () {
    testWidgets('displays tags correctly', (WidgetTester tester) async {
      // Arrange
      final testTags = [
        Tag(
          id: 'tag1',
          title: 'Friendly',
          count: 3,
          timestamp: Timestamp.now(),
        ),
        Tag(
          id: 'tag2',
          title: 'Energetic',
          count: 1,
          timestamp: Timestamp.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagsWidget(
              tags: testTags,
              isAdmin: false,
              onDelete: (tagId) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Friendly'), findsOneWidget);
      expect(find.text('Energetic'), findsOneWidget);
      expect(find.text('Count: 3'), findsOneWidget);
      expect(find.text('Count: 1'), findsNothing); // count of 1 should not show
      expect(find.byIcon(Icons.label), findsNWidgets(2));
    });

    testWidgets('shows delete buttons for admin users', (WidgetTester tester) async {
      // Arrange
      final testTags = [
        Tag(
          id: 'tag1',
          title: 'Friendly',
          count: 2,
          timestamp: Timestamp.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagsWidget(
              tags: testTags,
              isAdmin: true,
              onDelete: (tagId) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('hides delete buttons for non-admin users', (WidgetTester tester) async {
      // Arrange
      final testTags = [
        Tag(
          id: 'tag1',
          title: 'Friendly',
          count: 2,
          timestamp: Timestamp.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagsWidget(
              tags: testTags,
              isAdmin: false,
              onDelete: (tagId) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('shows confirmation dialog and calls onDelete when confirmed', (WidgetTester tester) async {
      // Arrange
      String? deletedTagId;
      final testTags = [
        Tag(
          id: 'tag1',
          title: 'Friendly',
          count: 2,
          timestamp: Timestamp.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagsWidget(
              tags: testTags,
              isAdmin: true,
              onDelete: (tagId) {
                deletedTagId = tagId;
              },
            ),
          ),
        ),
      );

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Assert confirmation dialog appears
      expect(find.text('Confirm Delete'), findsOneWidget);
      expect(find.text('Are you sure you want to delete the tag "Friendly"?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Assert onDelete was called with correct tag ID
      expect(deletedTagId, equals('tag1'));
    });

    testWidgets('does not call onDelete when deletion is cancelled', (WidgetTester tester) async {
      // Arrange
      String? deletedTagId;
      final testTags = [
        Tag(
          id: 'tag1',
          title: 'Friendly',
          count: 2,
          timestamp: Timestamp.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagsWidget(
              tags: testTags,
              isAdmin: true,
              onDelete: (tagId) {
                deletedTagId = tagId;
              },
            ),
          ),
        ),
      );

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Tap cancel in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert onDelete was not called
      expect(deletedTagId, isNull);
    });

    testWidgets('displays empty state when no tags', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagsWidget(
              tags: const [],
              isAdmin: false,
              onDelete: (tagId) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('No tags available'), findsOneWidget);
    });
  });
}