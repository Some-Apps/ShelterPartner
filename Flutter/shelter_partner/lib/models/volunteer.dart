class Volunteer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  Volunteer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  // Convert Volunteer to Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }

  // Factory constructor to create Volunteer from Firestore Map
  factory Volunteer.fromMap(Map<String, dynamic> data) {
    return Volunteer(
      id: data['id'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
    );
  }
}
