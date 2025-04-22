import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Photo {
  final String id;
  final String url;
  final Timestamp timestamp;
  final String author;
  final String authorID;
  final String source;

  Photo({
    required this.id,
    required this.url,
    required this.timestamp,
    required this.author,
    required this.authorID,
    this.source = 'manual', // Default to manual for backward compatibility
  });

  factory Photo.fromMap(Map<String, dynamic> data) {
    return Photo(
      id: data['id'] ?? const Uuid().v4(),
      url: data['url'] ?? "Unknown",
      timestamp: data['timestamp'] ?? Timestamp.now(),
      author: data['author'] ?? "Unknown",
      authorID: data['authorID'] ?? "Unknown",
      source: data['source'] ?? 'manual', // Handle missing source field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'timestamp': timestamp,
      'author': author,
      'authorID': authorID,
      'source': source,
    };
  }

  Photo copyWith({
    String? id,
    String? url,
    Timestamp? timestamp,
    String? author,
    String? authorID,
    String? source,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
      author: author ?? this.author,
      authorID: authorID ?? this.authorID,
      source: source ?? this.source,
    );
  }
}
