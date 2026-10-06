class DayOverride {
  final String date;
  final List<Map<String, dynamic>> classes;

  DayOverride({
    required this.date,
    required this.classes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'classes': classes,
    };
  }

  factory DayOverride.fromMap(Map<String, dynamic> map) {
    return DayOverride(
      date: map['date'] as String,
      classes: (map['classes'] as List)
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList(),
    );
  }
}