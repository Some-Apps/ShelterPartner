import 'package:cloud_firestore/cloud_firestore.dart';

class Shelter {
  final String id;
  final String address;
  final Timestamp createdAt;
  final String managementSoftware;
  final ShelterSettings shelterSettings; // Use ShelterSettings class
  final VolunteerSettings volunteerSettings; // Use VolunteerSettings class

  Shelter({
    required this.id,
    required this.address,
    required this.createdAt,
    required this.managementSoftware,
    required this.shelterSettings,
    required this.volunteerSettings,
  });

  // Factory constructor to parse the document from Firestore
  factory Shelter.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shelter(
      id: doc.id,
      address: data['address'],
      createdAt: data['createdAt'],
      managementSoftware: data['management_software'],
      shelterSettings: ShelterSettings.fromMap(data['shelterSettings'] ?? {}),
      volunteerSettings: VolunteerSettings.fromMap(data['volunteerSettings'] ?? {}),
    );
  }
}

class ShelterSettings {
  final String setting1;


  ShelterSettings({
    required this.setting1,
  });

  // Factory constructor to parse the shelter settings map from Firestore
  factory ShelterSettings.fromMap(Map<String, dynamic> data) {
    return ShelterSettings(
      setting1: data['setting1'] ?? "Unknown",
    );
  }

  // To map this object back to Firestore format if needed
  Map<String, dynamic> toMap() {
    return {
      'isOpen': setting1,
    };
  }
}

class VolunteerSettings {
  final String setting1;


  VolunteerSettings({
    required this.setting1,
  });

  // Factory constructor to parse the shelter settings map from Firestore
  factory VolunteerSettings.fromMap(Map<String, dynamic> data) {
    return VolunteerSettings(
      setting1: data['setting1'] ?? "Unknown",
    );
  }

  // To map this object back to Firestore format if needed
  Map<String, dynamic> toMap() {
    return {
      'isOpen': setting1,
    };
  }
}
