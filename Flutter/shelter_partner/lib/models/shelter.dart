import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/device_settings.dart';
import 'package:shelter_partner/models/shelter_settings.dart';
import 'package:shelter_partner/models/volunteer.dart';
import 'package:shelter_partner/models/volunteer_settings.dart';

class Shelter {
  final String id;
  final String name;
  final String address;
  final Timestamp createdAt;
  final String managementSoftware;

  final ShelterSettings shelterSettings;
  final DeviceSettings deviceSettings;
  final VolunteerSettings volunteerSettings;
  final List<Volunteer> volunteers;

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    required this.managementSoftware,
    required this.shelterSettings,
    required this.deviceSettings,
    required this.volunteerSettings,
    required this.volunteers
  });

  // Factory constructor to parse the document from Firestore
  factory Shelter.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safely handle the `createdAt` field to ensure it's a valid `Timestamp`.
    return Shelter(
      id: doc.id,
      name: data['name'] ?? 'Unknown Shelter', // Default value for name
      address: data['address'] ?? 'Unknown Address', // Default value for address
      createdAt: data['createdAt'] != null
          ? data['createdAt'] as Timestamp
          : Timestamp.now(), // Default value if createdAt is null
      managementSoftware: data['management_software'] ?? 'Unknown Software', // Default value for management software
      shelterSettings: ShelterSettings.fromMap(data['shelterSettings'] ?? {}),
      deviceSettings: DeviceSettings.fromMap(data['deviceSettings'] ?? {}),
      volunteerSettings: VolunteerSettings.fromMap(data['volunteerSettings'] ?? {}),
      volunteers: (data['volunteers'] as List<dynamic>? ?? [])
          .map((volunteer) => Volunteer.fromMap(volunteer as Map<String, dynamic>))
          .toList(),
    );
  }
}
