import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/models/photo.dart';
import 'package:shelter_partner/models/tag.dart';

class Animal {
  final String id;
  final String name;
  final String sex;
  final int monthsOld;
  final String species;
  final String breed;
  final String location;
  final String fullLocation;
  final String description;
  final String symbol;
  final String symbolColor;
  final String takeOutAlert;
  final String putBackAlert;

  final String adoptionCategory;
  final String behaviorCategory;
  final String locationCategory;
  final String medicalCategory;
  final String volunteerCategory;

  final bool inKennel;

  final Timestamp? intakeDate;

  final List<Photo>? photos;
  final List<Note> notes;
  final List<Log> logs;
  final List<Tag> tags;

  Animal({
    required this.id,
    required this.name,
    required this.sex,
    required this.monthsOld,
    required this.species,
    required this.breed,
    required this.location,
    required this.fullLocation,
    required this.description,
    required this.symbol,
    required this.symbolColor,
    required this.takeOutAlert,
    required this.putBackAlert,
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
    monthsOld: data['monthsOld'] ?? 0,
    species: data['species'] ?? 'Unknown',
    breed: data['breed'] ?? 'Unknown',
    location: data['location'] ?? 'Unknown',
    fullLocation: data['fullLocation'] ?? 'Unknown',
    description: data['description'] ?? 'No description available.',
    symbol: data['symbol'] ?? 'tag',
    symbolColor: data['symbolColor'] ?? 'red',
    takeOutAlert: data['takeOutAlert'] ?? 'Unknown',
    putBackAlert: data['putBackAlert'] ?? 'Unknown',
    adoptionCategory: data['adoptionCategory'] ?? 'Unknown',
    behaviorCategory: data['behaviorCategory'] ?? 'Unknown',
    locationCategory: data['locationCategory'] ?? 'Unknown',
    medicalCategory: data['medicalCategory'] ?? 'Unknown',
    volunteerCategory: data['volunteerCategory'] ?? 'Unknown',
    inKennel: data['inKennel'] ?? true,
    intakeDate: data['intakeDate'],
    photos: (data['photos'] is List) ? (data['photos'] as List).map((photo) => Photo.fromMap(photo)).toList() : [],
    notes: (data['notes'] is List) ? (data['notes'] as List).map((note) => Note.fromMap(note)).toList() : [],
    logs: (data['logs'] is List) ? (data['logs'] as List).map((log) => Log.fromMap(log)).toList() : [],
    tags: (data['tags'] is List) ? (data['tags'] as List).map((tag) => Tag.fromMap(tag)).toList() : [],
  );
}


  // Add copyWith method
  Animal copyWith({
    String? id,
    String? name,
    String? sex,
    int? monthsOld,
    String? species,
    String? breed,
    String? location,
    String? fullLocation,
    String? description,
    String? symbol,
    String? symbolColor,
    String? takeOutAlert,
    String? putBackAlert,
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
      monthsOld: monthsOld ?? this.monthsOld,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      location: location ?? this.location,
      fullLocation: fullLocation ?? this.fullLocation,
      description: description ?? this.description,
      symbol: symbol ?? this.symbol,
      symbolColor: symbolColor ?? this.symbolColor,
      takeOutAlert: takeOutAlert ?? this.takeOutAlert,
      putBackAlert: putBackAlert ?? this.putBackAlert,
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
  
  // Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sex': sex,
      'monthsOld': monthsOld,
      'species': species,
      'breed': breed,
      'location': location,
      'fullLocation': fullLocation,
      'description': description,
      'symbol': symbol,
      'symbolColor': symbolColor,
      'takeOutAlert': takeOutAlert,
      'putBackAlert': putBackAlert,
      'adoptionCategory': adoptionCategory,
      'behaviorCategory': behaviorCategory,
      'locationCategory': locationCategory,
      'medicalCategory': medicalCategory,
      'volunteerCategory': volunteerCategory,
      'inKennel': inKennel,
      'intakeDate': intakeDate,
      'photos': photos?.map((photo) => photo.toMap()).toList(),
      'notes': notes.map((note) => note.toMap()).toList(),
      'logs': logs.map((log) => log.toMap()).toList(),
      'tags': tags.map((tag) => tag.toMap()).toList(),
    };
  }
}
