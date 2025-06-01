import 'package:cloud_firestore/cloud_firestore.dart';

class Tag {
  final String id;
  final String title;
  final int count;
  final Timestamp timestamp;

  Tag({
    required this.id,
    required this.title,
    required this.count,
    required this.timestamp,
  });

  factory Tag.fromMap(Map<String, dynamic> data) {
    return Tag(
      id: data['id'] ?? "Unknown",
      title: data['title'] ?? "Unknown",
      count: data['count'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'count': count, 'timestamp': timestamp};
  }
}
