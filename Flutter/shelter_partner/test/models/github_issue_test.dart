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
      expect(issue.imageBase64, isNull);
      expect(issue.imageName, isNull);
    });

    test('should create instance with image data', () {
      const issue = GitHubIssue(
        title: 'Test Issue',
        body: 'Test Description',
        labels: ['user feedback'],
        imageBase64: 'base64data',
        imageName: 'screenshot.png',
      );

      expect(issue.title, 'Test Issue');
      expect(issue.body, 'Test Description');
      expect(issue.labels, ['user feedback']);
      expect(issue.imageBase64, 'base64data');
      expect(issue.imageName, 'screenshot.png');
    });

    test('should convert to JSON correctly without image', () {
      const issue = GitHubIssue(
        title: 'Test Issue',
        body: 'Test Description',
        labels: ['user feedback', 'bug'],
      );

      final json = issue.toJson();

      expect(json['title'], 'Test Issue');
      expect(json['body'], 'Test Description');
      expect(json['labels'], ['user feedback', 'bug']);
      expect(json.containsKey('imageBase64'), false);
      expect(json.containsKey('imageName'), false);
    });

    test('should convert to JSON correctly with image', () {
      const issue = GitHubIssue(
        title: 'Test Issue',
        body: 'Test Description',
        labels: ['user feedback'],
        imageBase64: 'base64data',
        imageName: 'test.png',
      );

      final json = issue.toJson();

      expect(json['title'], 'Test Issue');
      expect(json['body'], 'Test Description');
      expect(json['labels'], ['user feedback']);
      expect(json['imageBase64'], 'base64data');
      expect(json['imageName'], 'test.png');
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
    test('should create instance from JSON without image info', () {
      final json = {
        'number': 123,
        'html_url': 'https://github.com/test/repo/issues/123',
        'title': 'Test Issue',
      };

      final response = GitHubIssueResponse.fromJson(json);

      expect(response.number, 123);
      expect(response.htmlUrl, 'https://github.com/test/repo/issues/123');
      expect(response.title, 'Test Issue');
      expect(response.imageUploaded, false);
      expect(response.imageUploadError, isNull);
    });

    test('should create instance from JSON with image success', () {
      final json = {
        'number': 123,
        'html_url': 'https://github.com/test/repo/issues/123',
        'title': 'Test Issue',
        'imageUploaded': true,
      };

      final response = GitHubIssueResponse.fromJson(json);

      expect(response.number, 123);
      expect(response.htmlUrl, 'https://github.com/test/repo/issues/123');
      expect(response.title, 'Test Issue');
      expect(response.imageUploaded, true);
      expect(response.imageUploadError, isNull);
    });

    test('should create instance from JSON with image error', () {
      final json = {
        'number': 123,
        'html_url': 'https://github.com/test/repo/issues/123',
        'title': 'Test Issue',
        'imageUploaded': false,
        'imageUploadError': 'Image too large',
      };

      final response = GitHubIssueResponse.fromJson(json);

      expect(response.number, 123);
      expect(response.htmlUrl, 'https://github.com/test/repo/issues/123');
      expect(response.title, 'Test Issue');
      expect(response.imageUploaded, false);
      expect(response.imageUploadError, 'Image too large');
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
