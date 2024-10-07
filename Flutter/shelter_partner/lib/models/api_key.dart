class APIKey {
  final String name;
  final String key;

  APIKey({
    required this.name,
    required this.key,
  });

  factory APIKey.fromMap(Map<String, dynamic> data) {
    return APIKey(
      name: data['name'] ?? "Unknown",
      key: data['key'] ?? "Unknown",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'key': key,
    };
  }
}

