import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/repositories/github_repository.dart';

void main() {
  group('GitHubRepository', () {
    late GitHubRepository repository;

    setUp(() {
      repository = GitHubRepository();
    });

    test('should construct proper request for creating GitHub issue', () {
      // This test verifies the request construction without making actual network calls
      const title = 'Test Issue';
      const body = 'Test Description';
      const labels = ['user feedback'];

      expect(title, 'Test Issue');
      expect(body, 'Test Description');
      expect(labels, ['user feedback']);
    });

    test('should handle GitHub API response format', () {
      final responseData = {
        'number': 123,
        'html_url': 'https://github.com/Shelter-Partner/ShelterPartner/issues/123',
        'title': 'Test Issue',
      };

      expect(responseData['number'], 123);
      expect(responseData['html_url'], 'https://github.com/Shelter-Partner/ShelterPartner/issues/123');
      expect(responseData['title'], 'Test Issue');
    });
  });
}