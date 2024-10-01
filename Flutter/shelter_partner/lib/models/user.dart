import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore timestamp

class User {
  final String id; // Using String for UUIDs
  final String firstName;
  final String lastName;
  final String type;
  final String shelterId;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.type,
    required this.shelterId,
  });

  // Factory method to create a User object from Firestore document
  factory User.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      firstName: data['first_name'],
      lastName: data['last_name'],
      type: data['type'],
      shelterId: data['shelter_id'],
    );
  }

  // Method to convert User object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'type': type,
      'shelter_id': shelterId,
    };
  }
}
