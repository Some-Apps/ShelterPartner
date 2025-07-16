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

  group('GitHubIssueResponse', () {
    test('should create instance from JSON', () {
      final json = {
        'number': 123,
        'html_url': 'https://github.com/test/repo/issues/123',
        'title': 'Test Issue',
      };

      final response = GitHubIssueResponse.fromJson(json);

      expect(response.number, 123);
      expect(response.htmlUrl, 'https://github.com/test/repo/issues/123');
      expect(response.title, 'Test Issue');
    });

    test('should handle different number types', () {
      final json = {
        'number': 456,
        'html_url': 'https://github.com/test/repo/issues/456',
        'title': 'Another Test Issue',
      };

      final response = GitHubIssueResponse.fromJson(json);

      expect(response.number, 456);
      expect(response.htmlUrl, 'https://github.com/test/repo/issues/456');
      expect(response.title, 'Another Test Issue');
    });
  });
}
