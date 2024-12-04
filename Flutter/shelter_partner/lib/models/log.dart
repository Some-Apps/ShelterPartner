import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Log {
  final String id;
  final String type;
  final String author;
  final String authorID;
  final String? earlyReason;
  final Timestamp startTime;
  final Timestamp endTime;

  Log({
    required this.id,
    required this.type,
    required this.author,
    required this.authorID,
    required this.startTime,
    required this.endTime,
    this.earlyReason,
  });

  factory Log.fromMap(Map<String, dynamic> data) {
    return Log(
      id: data['id'] ?? const Uuid().v4(),
      type: data['type'] ?? "Unknown",
      author: data['author'] ?? "Unknown",
      authorID: data['authorID'] ?? "Unknown",
      startTime: data['startTime'] ?? Timestamp.now(),
      endTime: data['endTime'] ?? Timestamp.now(),
      earlyReason: data['earlyReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'author': author,
      'authorID': authorID,
      'startTime': startTime,
      'endTime': endTime,
      'earlyReason': earlyReason,
    };
  }

  Log copyWith({
    String? id,
    String? type,
    String? author,
    String? authorID,
    Timestamp? startTime,
    Timestamp? endTime,
    String? earlyReason,
  }) {
    return Log(
      id: id ?? this.id,
      type: type ?? this.type,
      author: author ?? this.author,
      authorID: authorID ?? this.authorID,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      earlyReason: earlyReason ?? this.earlyReason,
    );
}
}