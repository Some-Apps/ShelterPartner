

class ScheduledReport {
  final String email;
  final List<String> days;
  final String type;

  ScheduledReport({
    required this.email,
    required this.days,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'days': days,
      'type': type,
    };
  }

  factory ScheduledReport.fromMap(Map<String, dynamic> data) {
    return ScheduledReport(
      email: data['email'] ?? "Unknown",
      days: List<String>.from(data['days'] ?? []),
      type: data['type'] ?? "Unknown",
    );
  }
}



