// For Firestore timestamp

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/photo.dart';

class Animal {
  final String id;
  final String name;
  final String species;
  final String location;

  final Timestamp? intakeDate;

  final List<Photo> photos;

  // todo: add rest of fields

  Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.location,

    required this.intakeDate,

    required this.photos,
  });

  factory Animal.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Animal(
      id: documentId,
      name: data['name'] ?? 'Unknown',
      species: data['species'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',

      intakeDate: data['intakeDate'],

      photos: (data['photos'] as List)
          .map((photo) => Photo.fromMap(photo))
          .toList(),
    );
  }

  static fromSnapshot(DocumentSnapshot<Object?> doc) {}
}
