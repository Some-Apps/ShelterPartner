import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String type;
  final String shelterId;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.type,
    required this.shelterId,
  });

  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      firstName: data['first_name'],
      lastName: data['last_name'],
      type: data['type'],
      shelterId: data['shelter_id'],
    );
  }
}
