// volunteer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String shelterID;
  final Timestamp lastActivity;
  final int averageLogDuration;
  final int totalTimeLoggedWithAnimals;

  Volunteer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.shelterID,
    required this.lastActivity,
    required this.averageLogDuration,
    required this.totalTimeLoggedWithAnimals,
  });

  // Factory constructor to create Volunteer from Firestore DocumentSnapshot
  factory Volunteer.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Volunteer(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      shelterID: data['shelterID'] ?? '',
      lastActivity: data['lastActivity'] ?? Timestamp.now(),
      averageLogDuration: data['averageLogDuration'] ?? 0,
      totalTimeLoggedWithAnimals: data['totalTimeLoggedWithAnimals'] ?? 0,
    );
  }

  // CopyWith method to create a new Volunteer object with updated properties
  Volunteer copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? shelterID,
    Timestamp? lastActivity,
    int? averageLogDuration,
    int? totalTimeLoggedWithAnimals,
  }) {
    return Volunteer(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      shelterID: shelterID ?? this.shelterID,
      lastActivity: lastActivity ?? this.lastActivity,
      averageLogDuration: averageLogDuration ?? this.averageLogDuration,
      totalTimeLoggedWithAnimals:
          totalTimeLoggedWithAnimals ?? this.totalTimeLoggedWithAnimals,
    );
  }
}
