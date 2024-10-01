import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore timestamp

class Animal {
  final String id;
  final String name;
  final String location;
  final String alert;
  final bool canPlay;
  final bool inKennel;
  final Timestamp startTime;
  final String description;

  Animal({
    required this.id,
    required this.name,
    required this.location,
    required this.alert,
    required this.canPlay,
    required this.inKennel,
    required this.startTime,
    required this.description,
  });

  factory Animal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Animal(
      id: doc.id,
      name: data['name'],
      location: data['location'],
      alert: data['alert'],
      canPlay: data['can_play'],
      inKennel: data['in_kennel'],
      startTime: data['start_time'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'alert': alert,
      'can_play': canPlay,
      'in_kennel': inKennel,
      'start_time': startTime,
      'description': description,
    };
  }
}
