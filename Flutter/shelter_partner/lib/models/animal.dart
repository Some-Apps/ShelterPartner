// For Firestore timestamp

import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String id;
  final String name;
  final String location;

  // todo: add rest of fields
  
  Animal({
    required this.id, 
    required this.name, 
    required this.location,
    });

  factory Animal.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Animal(
      id: documentId,
      name: data['name'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
    );
  }

  static fromSnapshot(DocumentSnapshot<Object?> doc) {}
}
