import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String note;
  final String author;
  final Timestamp timestamp;

  Note({
    required this.id,
    required this.note,
    required this.author,
    required this.timestamp,
  });

  factory Note.fromMap(Map<String, dynamic> data) {
    return Note(
      id: data['id'] ?? const Uuid().v4(),
      note: data['note'] ?? "Unknown",
      author: data['author'] ?? "Unknown",
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'author': author,
      'timestamp': timestamp,
    };
  }
}
