import 'package:uuid/uuid.dart';

class TimetableEntry {
  String id;
  String day;
  String subject;

  TimetableEntry({
    String? id,
    required this.day,
    required this.subject,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'subject': subject,
    };
  }

  factory TimetableEntry.fromMap(
    Map<String, dynamic> map,
  ) {
    return TimetableEntry(
      id: map['id'] as String?,
      day: map['day'] as String,
      subject: map['subject'] as String,
    );
  }
}