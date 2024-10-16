import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/models/photo.dart';

class Animal {
  final String id;
  final String name;
  final String sex;
  final String age;
  final String species;
  final String breed;
  final String location;
  final String description;

  final bool inKennel;

  final Timestamp? intakeDate;

  final List<Photo> photos;
  final List<Note> notes;
  final List<Log> logs;


  Animal({
    required this.id,
    required this.name,
    required this.sex,
    required this.age,
    required this.species,
    required this.breed,
    required this.location,
    required this.description,

    required this.inKennel,

    required this.intakeDate,

    required this.photos,
    required this.notes,
    required this.logs
  });

  factory Animal.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Animal(
      id: documentId,
      name: data['name'] ?? 'Unknown',
      sex: data['sex'] ?? 'Unknown',
      age: data['age'] ?? 'Unknown',
      species: data['species'] ?? 'Unknown',
      breed: data['breed'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
      description: data['description'] ?? 'No description available.',

      inKennel: data['inKennel'] ?? true,

      intakeDate: data['intakeDate'],

      photos: (data['photos'] as List)
          .map((photo) => Photo.fromMap(photo))
          .toList(),
      notes: (data['notes'] as List)
          .map((note) => Note.fromMap(note))
          .toList(),
      logs: (data['logs'] as List)
          .map((log) => Log.fromMap(log))
          .toList(),
    );
  }

  static fromSnapshot(DocumentSnapshot<Object?> doc) {}
}
