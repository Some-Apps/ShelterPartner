import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/tag.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';

Tag testTag({String id = 'tag1', String title = 'Friendly'}) => Tag(
      id: id,
      title: title,
      count: 1,
      timestamp: Timestamp.now(),
    );

Animal createTestAnimal({
  required String id,
  required String name,
  String sex = 'm',
  int monthsOld = 12,
  String species = 'dog',
  String breed = 'Mixed',
  String location = 'Kennel A',
  String fullLocation = 'Shelter A > Building 1 > Room A > Kennel 1',
  String description = 'A friendly animal.',
  String symbol = 'pets',
  String symbolColor = 'brown',
  String takeOutAlert = 'Needs leash',
  String putBackAlert = 'Check water bowl',
  String adoptionCategory = 'Adoption 1',
  String behaviorCategory = 'Behavior 1',
  String locationCategory = 'Building 1',
  String medicalCategory = 'Medical 1',
  String volunteerCategory = 'Red',
  bool inKennel = true,
  DateTime? intakeDate,
  List<Tag>? tags,
  List<Log>? logs,
}) {
  final now = DateTime.now();
  final defaultLog = Log(
    id: 'log1',
    type: 'let out',
    author: 'Test User',
    authorID: 'test-user-id',
    earlyReason: '',
    startTime: Timestamp.fromDate(
        intakeDate ?? now.subtract(const Duration(hours: 2))),
    endTime: Timestamp.fromDate(
        intakeDate ?? now.subtract(const Duration(hours: 1))),
  );
  final animal = Animal(
    id: id,
    name: name,
    sex: sex,
    monthsOld: monthsOld,
    species: species,
    breed: breed,
    location: location,
    fullLocation: fullLocation,
    description: description,
    symbol: symbol,
    symbolColor: symbolColor,
    takeOutAlert: takeOutAlert,
    putBackAlert: putBackAlert,
    adoptionCategory: adoptionCategory,
    behaviorCategory: behaviorCategory,
    locationCategory: locationCategory,
    medicalCategory: medicalCategory,
    volunteerCategory: volunteerCategory,
    inKennel: inKennel,
    intakeDate: Timestamp.fromDate(intakeDate ?? DateTime(2025, 5, 30)),
    photos: const [],
    notes: const [],
    logs: logs ?? [defaultLog],
    tags: tags ?? [testTag()],
  );
  return animal;
}

Map<String, dynamic> createTestAnimalData({
  required String id,
  required String name,
  String sex = 'm',
  int monthsOld = 12,
  String species = 'dog',
  String breed = 'Mixed',
  String location = 'Kennel A',
  String fullLocation = 'Shelter A > Building 1 > Room A > Kennel 1',
  String description = 'A friendly animal.',
  String symbol = 'pets',
  String symbolColor = 'brown',
  String takeOutAlert = 'Needs leash',
  String putBackAlert = 'Check water bowl',
  String adoptionCategory = 'Adoption 1',
  String behaviorCategory = 'Behavior 1',
  String locationCategory = 'Building 1',
  String medicalCategory = 'Medical 1',
  String volunteerCategory = 'Red',
  bool inKennel = true,
  DateTime? intakeDate,
  List<Tag>? tags,
  List<Log>? logs,
}) {
  final animal = createTestAnimal(
    id: id,
    name: name,
    sex: sex,
    monthsOld: monthsOld,
    species: species,
    breed: breed,
    location: location,
    fullLocation: fullLocation,
    description: description,
    symbol: symbol,
    symbolColor: symbolColor,
    takeOutAlert: takeOutAlert,
    putBackAlert: putBackAlert,
    adoptionCategory: adoptionCategory,
    behaviorCategory: behaviorCategory,
    locationCategory: locationCategory,
    medicalCategory: medicalCategory,
    volunteerCategory: volunteerCategory,
    inKennel: inKennel,
    intakeDate: intakeDate,
    tags: tags,
    logs: logs,
  );
  return animal.toMap();
}
