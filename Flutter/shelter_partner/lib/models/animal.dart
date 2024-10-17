import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/models/photo.dart';
import 'package:shelter_partner/models/tag.dart';

class Animal {
  final String id;
  final String name;
  final String sex;
  final String age;
  final String species;
  final String breed;
  final String location;
  final String description;

  final String adoptionCategory;
  final String behaviorCategory;
  final String locationCategory;
  final String medicalCategory;
  final String volunteerCategory;

  final bool inKennel;

  final Timestamp? intakeDate;

  final List<Photo> photos;
  final List<Note> notes;
  final List<Log> logs;
  final List<Tag> tags;

  Animal({
    required this.id,
    required this.name,
    required this.sex,
    required this.age,
    required this.species,
    required this.breed,
    required this.location,
    required this.description,
    required this.adoptionCategory,
    required this.behaviorCategory,
    required this.locationCategory,
    required this.medicalCategory,
    required this.volunteerCategory,
    required this.inKennel,
    required this.intakeDate,
    required this.photos,
    required this.notes,
    required this.logs,
    required this.tags,
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
      adoptionCategory: data['adoptionCategory'] ?? 'Unknown',
      behaviorCategory: data['behaviorCategory'] ?? 'Unknown',
      locationCategory: data['locationCategory'] ?? 'Unknown',
      medicalCategory: data['medicalCategory'] ?? 'Unknown',
      volunteerCategory: data['volunteerCategory'] ?? 'Unknown',
      inKennel: data['inKennel'] ?? true,
      intakeDate: data['intakeDate'],
      photos: (data['photos'] as List)
          .map((photo) => Photo.fromMap(photo))
          .toList(),
      notes: (data['notes'] as List).map((note) => Note.fromMap(note)).toList(),
      logs: (data['logs'] as List).map((log) => Log.fromMap(log)).toList(),
      tags: (data['tags'] as List).map((tag) => Tag.fromMap(tag)).toList(),
    );
  }

  // Add copyWith method
  Animal copyWith({
    String? id,
    String? name,
    String? sex,
    String? age,
    String? species,
    String? breed,
    String? location,
    String? description,
    String? adoptionCategory,
    String? behaviorCategory,
    String? locationCategory,
    String? medicalCategory,
    String? volunteerCategory,
    bool? inKennel,
    Timestamp? intakeDate,
    List<Photo>? photos,
    List<Note>? notes,
    List<Log>? logs,
    List<Tag>? tags,
  }) {
    return Animal(
      id: id ?? this.id,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      location: location ?? this.location,
      description: description ?? this.description,
      adoptionCategory: adoptionCategory ?? this.adoptionCategory,
      behaviorCategory: behaviorCategory ?? this.behaviorCategory,
      locationCategory: locationCategory ?? this.locationCategory,
      medicalCategory: medicalCategory ?? this.medicalCategory,
      volunteerCategory: volunteerCategory ?? this.volunteerCategory,
      inKennel: inKennel ?? this.inKennel,
      intakeDate: intakeDate ?? this.intakeDate,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      logs: logs ?? this.logs,
      tags: tags ?? this.tags,
    );
  }
}
