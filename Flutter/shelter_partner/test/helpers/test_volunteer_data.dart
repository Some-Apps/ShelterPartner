import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/models/shelter.dart';
import 'package:shelter_partner/models/shelter_settings.dart';
import 'package:shelter_partner/models/volunteer_settings.dart';

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

/// Creates a test Shelter object with volunteers for testing
Shelter createTestShelterWithVolunteers({
  String shelterId = 'test-shelter',
  String name = 'Test Shelter',
  String address = '123 Test St',
  List<Volunteer> volunteers = const [],
}) {
  return Shelter(
    id: shelterId,
    name: name,
    address: address,
    createdAt: Timestamp.now(),
    managementSoftware: 'ShelterLuv',
    shelterSettings: ShelterSettings.fromMap({}),
    volunteerSettings: VolunteerSettings.fromMap({}),
    volunteers: volunteers,
  );
}
