import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelter_partner/models/github_issue.dart';

class GitHubRepository {
  // Cloud Function URL for GitHub issue proxy
  static const String _cloudFunctionUrl =
      'https://us-central1-shelterpartner-42b4c.cloudfunctions.net/create_github_issue';

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
