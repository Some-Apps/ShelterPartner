import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelter_partner/models/github_issue.dart';

class GitHubRepository {
  // Cloud Function URL for GitHub issue proxy
  static const String _cloudFunctionUrl =
      'https://github-issue-proxy-222422545919.europe-west1.run.app';

  Future<GitHubIssueResponse> createIssue({
    required String title,
    required String body,
    List<String> labels = const ['user feedback'],
  }) async {
    final issue = GitHubIssue(title: title, body: body, labels: labels);

    final response = await http.post(
      Uri.parse(_cloudFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'ShelterPartner-App',
      },
      body: jsonEncode(issue.toJson()),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return GitHubIssueResponse.fromJson(responseData);
    } else {
      throw Exception(
        'Failed to create GitHub issue: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
