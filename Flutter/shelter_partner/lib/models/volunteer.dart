class Volunteer {
  final String id;
  final String name;   


  Volunteer({
    required this.id,
    required this.name,
  });

  // Convert Volunteer to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Factory constructor to create Volunteer from Firestore Map
  factory Volunteer.fromMap(Map<String, dynamic> data) {
    return Volunteer(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
    );
  }
}
