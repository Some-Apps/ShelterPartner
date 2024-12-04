import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Photo {
  final String id;
  final String url;
  final Timestamp timestamp;
  final String author;
  final String authorID;

  Photo({
    required this.id,
    required this.url,
    required this.timestamp,
    required this.author,
    required this.authorID,
  });

  factory Photo.fromMap(Map<String, dynamic> data) {
    return Photo(
      id: data['id'] ?? const Uuid().v4(),
      url: data['url'] ?? "Unknown",
      timestamp: data['timestamp'] ?? Timestamp.now(),
      author: data['author'] ?? "Unknown",
      authorID: data['authorID'] ?? "Unknown",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'timestamp': timestamp,
      'author': author,
      'authorID': authorID,
    };
  }

  Photo copyWith({
    String? id,
    String? url,
    Timestamp? timestamp,
    String? author,
    String? authorID,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
      author: author ?? this.author,
      authorID: authorID ?? this.authorID,
    );
  }
}
