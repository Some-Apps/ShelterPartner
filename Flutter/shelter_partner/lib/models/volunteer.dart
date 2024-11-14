import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  final Timestamp lastActivity;
  final int averageLogDuration;
  final int totalTimeLoggedWithAnimals;

  Volunteer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,

    required this.lastActivity,
    required this.averageLogDuration,
    required this.totalTimeLoggedWithAnimals,
  });

  // Convert Volunteer to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,

      'lastActivity': lastActivity,
      'averageLogDuration': averageLogDuration,
      'totalTimeLoggedWithAnimals': totalTimeLoggedWithAnimals,
    };
  }

  // Factory constructor to create Volunteer from Firestore Map
  factory Volunteer.fromMap(Map<String, dynamic> data) {
    return Volunteer(
      id: data['id'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',

      lastActivity: data['lastActivity'] ?? Timestamp.now(),
      averageLogDuration: data['averageLogDuration'] ?? 24,
      totalTimeLoggedWithAnimals: data['totalTimeLoggedWithAnimals'] ?? 319,
    );
  }
}
