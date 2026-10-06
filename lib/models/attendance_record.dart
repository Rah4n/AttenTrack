class AttendanceRecord {
  final String subject;
  final DateTime date;
  final int hours;
  final bool present;

  AttendanceRecord({
    required this.subject,
    required this.date,
    required this.hours,
    required this.present,
  });
}