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
    return {'title': title, 'body': body, 'labels': labels};
  }
}
