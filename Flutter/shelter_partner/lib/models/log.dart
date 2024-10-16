import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Log {
  final String id;
  final String type;
  final String author;
  final String? earlyReason;
  final Timestamp startTime;
  final Timestamp endTime;

  Log({
    required this.id,
    required this.type,
    required this.author,
    required this.startTime,
    required this.endTime,
    this.earlyReason,
  });

  factory Log.fromMap(Map<String, dynamic> data) {
    return Log(
      id: data['id'] ?? const Uuid().v4(),
      type: data['type'] ?? "Unknown",
      author: data['author'] ?? "Unknown",
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
      'startTime': startTime,
      'endTime': endTime,
      'earlyReason': earlyReason,
    };
  }
}
