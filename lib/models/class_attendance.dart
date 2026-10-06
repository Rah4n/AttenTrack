class ClassAttendance {
  final String date;
  final String classId;
  final String subject;
  final String status; // "present" or "absent"

  ClassAttendance({
    required this.date,
    required this.classId,
    required this.subject,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'classId': classId,
      'subject': subject,
      'status': status,
    };
  }

  factory ClassAttendance.fromMap(
    Map<String, dynamic> map,
  ) {
    return ClassAttendance(
      date: map['date'] as String,
      classId: map['classId'] as String,
      subject: map['subject'] as String,
      status: map['status'] as String,
    );
  }
}