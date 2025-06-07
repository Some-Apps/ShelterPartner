import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/volunteer.dart';

/// Creates test volunteer data for testing
Map<String, dynamic> createTestVolunteerData({
  String id = 'volunteer1',
  String firstName = 'John',
  String lastName = 'Doe',
  String email = 'john.doe@example.com',
  String shelterID = 'test-shelter',
  Timestamp? lastActivity,
  int averageLogDuration = 30,
  int totalTimeLoggedWithAnimals = 120,
}) {
  return {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'shelterID': shelterID,
    'lastActivity': lastActivity ?? Timestamp.now(),
    'averageLogDuration': averageLogDuration,
    'totalTimeLoggedWithAnimals': totalTimeLoggedWithAnimals,
  };
}

/// Creates a test Volunteer object for testing
Volunteer createTestVolunteer({
  String id = 'volunteer1',
  String firstName = 'John',
  String lastName = 'Doe',
  String email = 'john.doe@example.com',
  String shelterID = 'test-shelter',
  Timestamp? lastActivity,
  int averageLogDuration = 30,
  int totalTimeLoggedWithAnimals = 120,
}) {
  return Volunteer(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    shelterID: shelterID,
    lastActivity: lastActivity ?? Timestamp.now(),
    averageLogDuration: averageLogDuration,
    totalTimeLoggedWithAnimals: totalTimeLoggedWithAnimals,
  );
}