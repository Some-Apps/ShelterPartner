class GitHubIssue {
  final String title;
  final String body;
  final List<String> labels;
  final String? imageBase64;
  final String? imageName;

  const GitHubIssue({
    required this.title,
    required this.body,
    required this.labels,
    this.imageBase64,
    this.imageName,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'labels': labels,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (imageName != null) 'imageName': imageName,
    };
  }
}

class GitHubIssueResponse {
  final int number;
  final String htmlUrl;
  final String title;
  final bool imageUploaded;
  final String? imageUploadError;

  const GitHubIssueResponse({
    required this.number,
    required this.htmlUrl,
    required this.title,
    this.imageUploaded = false,
    this.imageUploadError,
  });

  factory GitHubIssueResponse.fromJson(Map<String, dynamic> json) {
    return GitHubIssueResponse(
      number: json['number'],
      htmlUrl: json['html_url'],
      title: json['title'],
      imageUploaded: json['imageUploaded'] ?? false,
      imageUploadError: json['imageUploadError'],
    );
  }
}
