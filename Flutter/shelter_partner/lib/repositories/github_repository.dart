import 'dart:convert';
import 'dart:typed_data';
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
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    String? imageBase64;

    // Convert image to base64 if provided
    if (imageBytes != null) {
      try {
        imageBase64 = base64Encode(imageBytes);
      } catch (e) {
        // If base64 conversion fails, continue without image
        imageBase64 = null;
      }
    }

    final issue = GitHubIssue(
      title: title,
      body: body,
      labels: labels,
      imageBase64: imageBase64,
      imageName: imageName,
    );

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
