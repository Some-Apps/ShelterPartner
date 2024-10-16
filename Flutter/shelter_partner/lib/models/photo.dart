import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Photo {
  final String id;
  final String url;
  final Timestamp timestamp;

  Photo({
    required this.id,
    required this.url,
    required this.timestamp,
  });

  factory Photo.fromMap(Map<String, dynamic> data) {
    return Photo(
      id: data['id'] ?? const Uuid().v4(),
      url: data['url'] ?? "Unknown",
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'timestamp': timestamp,
    };
  }
}
