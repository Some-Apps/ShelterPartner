// For Firestore timestamp

import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String id;
  final String name;
  final int age;
  
  Animal({required this.id, required this.name, required this.age});

  factory Animal.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Animal(
      id: documentId,
      name: data['name'] ?? 'Unknown',
      age: data['age'] ?? 0,
    );
  }

  static fromSnapshot(DocumentSnapshot<Object?> doc) {}
}
