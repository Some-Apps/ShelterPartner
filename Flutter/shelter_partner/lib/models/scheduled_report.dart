class ScheduledReport {
  final String id;
  final String title;
  final String email;
  final String frequency;
  final String dayOfWeek;
  final int dayOfMonth;

  ScheduledReport({
    required this.id,
    required this.title,
    required this.email,
    required this.frequency,
    required this.dayOfWeek,
    required this.dayOfMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'email': email,
      'frequency': frequency,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
    };
  }

  factory ScheduledReport.fromMap(Map<String, dynamic> data) {
    return ScheduledReport(
      id: data['id'] ?? "Unknown",
      title: data['title'] ?? "Unknown",
      email: data['email'] ?? "Unknown",
      frequency: data['frequency'] ?? "Unknown",
      dayOfWeek: data['dayOfWeek'] ?? "Unknown",
      dayOfMonth: data['dayOfMonth'] ?? 0,
    );
  }
}
