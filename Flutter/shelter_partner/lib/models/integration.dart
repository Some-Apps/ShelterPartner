import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Integration {
  final String id;
  final String type;
  final String key;
  final String? username;
  final Timestamp password;

  Integration({
    required this.id,
    required this.type,
    required this.key,
    required this.username,
    required this.password,
  });

  factory Integration.fromMap(Map<String, dynamic> data) {
    return Integration(
      id: data['id'] ?? const Uuid().v4(),
      type: data['type'] ?? "Unknown",
      key: data['key'] ?? "Unknown",
      username: data['username'] ?? "Unknown",
      password: data['password'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'key': key,
      'username': username,
      'password': password,
    };
  }

  Integration copyWith({
    String? id,
    String? type,
    String? key,
    String? username,
    Timestamp? password,
  }) {
    return Integration(
      id: id ?? this.id,
      type: type ?? this.type,
      key: key ?? this.key,
      username: username ?? this.username,
      password: password ?? this.password,
    );
}
}