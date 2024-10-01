import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerSettings {
  final String id; // Shelter ID
  final String setting1;
  final String setting2;

  VolunteerSettings({
    required this.id,
    required this.setting1,
    required this.setting2,
  });

  factory VolunteerSettings.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VolunteerSettings(
      id: doc.id,
      setting1: data['setting_1'],
      setting2: data['setting_2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setting_1': setting1,
      'setting_2': setting2,
    };
  }
}
