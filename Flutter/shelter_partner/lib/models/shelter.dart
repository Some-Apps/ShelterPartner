// shelter.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/shelter_settings.dart';
import 'package:shelter_partner/models/volunteer_settings.dart';
import 'volunteer.dart';

class Shelter {
  final String id;
  final String name;
  final String address;
  final Timestamp createdAt;
  final String managementSoftware;
  final ShelterSettings shelterSettings;
  final VolunteerSettings volunteerSettings;
  List<Volunteer> volunteers;

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    required this.managementSoftware,
    required this.shelterSettings,
    required this.volunteerSettings,
    required this.volunteers,
  });

  // Factory constructor to parse the document from Firestore
  factory Shelter.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Shelter(
      id: doc.id,
      name: data['name'] ?? 'Unknown Shelter',
      address: data['address'] ?? 'Unknown Address',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      managementSoftware: data['managementSoftware'] ?? 'Unknown Software',
      shelterSettings: ShelterSettings.fromMap(data['shelterSettings'] ?? {}),
      volunteerSettings: VolunteerSettings.fromMap(data['volunteerSettings'] ?? {}),
      volunteers: [], // Initialize with an empty list
    );
  }

  Shelter copyWith({
    String? id,
    String? name,
    String? address,
    Timestamp? createdAt,
    String? managementSoftware,
    ShelterSettings? shelterSettings,
    VolunteerSettings? volunteerSettings,
    List<Volunteer>? volunteers,
  }) {
    return Shelter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      managementSoftware: managementSoftware ?? this.managementSoftware,
      shelterSettings: shelterSettings ?? this.shelterSettings,
      volunteerSettings: volunteerSettings ?? this.volunteerSettings,
      volunteers: volunteers ?? this.volunteers,
    );
  }
}
