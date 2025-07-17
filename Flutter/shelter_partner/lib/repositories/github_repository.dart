import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelter_partner/models/github_issue.dart';

class GitHubRepository {
  // Zapier webhook URL for handling feedback submissions
  static const String _zapierWebhookUrl =
      'https://hooks.zapier.com/hooks/catch/20574970/u2gqfgb/';

  Future<void> submitFeedback({
    required String title,
    required String body,
    List<String> labels = const ['user feedback'],
  }) async {
    final issue = GitHubIssue(title: title, body: body, labels: labels);

    final response = await http.post(
      Uri.parse(_zapierWebhookUrl),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'ShelterPartner-App',
      },
      body: jsonEncode(issue.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to submit feedback: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
