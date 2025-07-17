import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/models/github_issue.dart';

void main() {
  group('GitHubIssue', () {
    test('should create instance with required fields', () {
      const issue = GitHubIssue(
        title: 'Test Issue',
        body: 'Test Description',
        labels: ['user feedback'],
      );

      expect(issue.title, 'Test Issue');
      expect(issue.body, 'Test Description');
      expect(issue.labels, ['user feedback']);
    });

    test('should convert to JSON correctly', () {
      const issue = GitHubIssue(
        title: 'Test Issue',
        body: 'Test Description',
        labels: ['user feedback', 'bug'],
      );

      final json = issue.toJson();

      expect(json['title'], 'Test Issue');
      expect(json['body'], 'Test Description');
      expect(json['labels'], ['user feedback', 'bug']);
    });

    test('should handle empty labels', () {
      const issue = GitHubIssue(
        title: 'Test Issue',
        body: 'Test Description',
        labels: [],
      );

      final json = issue.toJson();
      expect(json['labels'], []);
    });
  });
}
