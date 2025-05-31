class GitHubRelease {
  final String version;
  final DateTime publishedAt;
  final String body;

  GitHubRelease({
    required this.version,
    required this.publishedAt,
    required this.body,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      version: json['tag_name'] ?? 'null',
      publishedAt: DateTime.parse(json['published_at']),
      body: json['body'] ?? '',
    );
  }
}
