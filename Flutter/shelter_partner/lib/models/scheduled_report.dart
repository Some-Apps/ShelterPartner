

class ScheduledReport {
  final String id;
  final String title;
  final String email;
  final String type;

  ScheduledReport({
    required this.id,
    required this.title,
    required this.email,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'email': email,
      'type': type,
    };
  }

  factory ScheduledReport.fromMap(Map<String, dynamic> data) {
    return ScheduledReport(
      id: data['id'] ?? "Unknown",
      title: data['title'] ?? "Unknown",
      email: data['email'] ?? "Unknown",
      type: data['type'] ?? "Unknown",
    );
  }
}



