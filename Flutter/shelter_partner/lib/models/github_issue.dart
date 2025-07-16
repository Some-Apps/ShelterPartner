class GitHubIssue {
  final String title;
  final String body;
  final List<String> labels;

  const GitHubIssue({
    required this.title,
    required this.body,
    required this.labels,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'labels': labels,
    };
  }
}

class GitHubIssueResponse {
  final int number;
  final String htmlUrl;
  final String title;

  const GitHubIssueResponse({
    required this.number,
    required this.htmlUrl,
    required this.title,
  });

  factory GitHubIssueResponse.fromJson(Map<String, dynamic> json) {
    return GitHubIssueResponse(
      number: json['number'],
      htmlUrl: json['html_url'],
      title: json['title'],
    );
  }
}