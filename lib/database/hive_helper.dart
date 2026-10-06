import 'package:hive_flutter/hive_flutter.dart';

import '../models/timetable_entry.dart';
import '../models/class_attendance.dart';
import '../models/day_override.dart';

class HiveHelper {
  static Box get box =>
      Hive.box("attendanceBox");

  // ==================================================
  // SUBJECT / COURSE
  // ==================================================

  static const String _subjectsKey =
      "subjects";

  static Future<void> saveSubjects(
    List<String> subjects,
  ) async {
    await box.put(
      _subjectsKey,
      List<String>.from(subjects),
    );
  }

  static List<String> getSubjects() {
    final data =
        box.get(_subjectsKey);

    if (data == null) {
      return [];
    }

    return List<String>.from(data);
  }

  // ==================================================
  // RENAME SUBJECT
  // ==================================================

  static Future<void> renameSubject(
    String oldName,
    String newName,
  ) async {
    if (oldName == newName) {
      return;
    }

    newName = newName.trim();

    if (newName.isEmpty) {
      return;
    }

    // -----------------------------------------------
    // UPDATE SUBJECT LIST
    // -----------------------------------------------

    final subjects =
        getSubjects();

    final index =
        subjects.indexOf(oldName);

    if (index != -1) {
      subjects[index] =
          newName;

      await saveSubjects(
        subjects,
      );
    }

    // -----------------------------------------------
    // UPDATE WEEKLY TIMETABLE
    // -----------------------------------------------

    final timetable =
        getTimetable();

    final updatedTimetable =
        <TimetableEntry>[];

    for (final entry in timetable) {
      if (entry.subject ==
          oldName) {
        updatedTimetable.add(
          TimetableEntry(
            id: entry.id,
            day: entry.day,
            subject: newName,
          ),
        );
      } else {
        updatedTimetable.add(
          entry,
        );
      }
    }

    await box.put(
      "timetable",
      updatedTimetable
          .map(
            (entry) =>
                entry.toMap(),
          )
          .toList(),
    );

    // -----------------------------------------------
    // UPDATE DAY OVERRIDES
    // -----------------------------------------------

    final overrideKeys =
        <String>[];

    for (final key in box.keys) {
      if (key
          .toString()
          .startsWith(
            "day_override_",
          )) {
        overrideKeys.add(
          key.toString(),
        );
      }
    }

    for (final key
        in overrideKeys) {
      final date =
          key.replaceFirst(
        "day_override_",
        "",
      );

      final override =
          getDayOverride(
        date,
      );

      if (override ==
          null) {
        continue;
      }

      final updatedClasses =
          <Map<String, dynamic>>[];

      for (final item
          in override.classes) {
        final entry =
            TimetableEntry
                .fromMap(
          Map<String, dynamic>
              .from(item),
        );

        if (entry.subject ==
            oldName) {
          updatedClasses.add(
            TimetableEntry(
              id: entry.id,
              day: entry.day,
              subject: newName,
            ).toMap(),
          );
        } else {
          updatedClasses.add(
            entry.toMap(),
          );
        }
      }

      await saveDayOverride(
        DayOverride(
          date: override.date,
          classes:
              updatedClasses,
        ),
      );
    }

    // -----------------------------------------------
    // UPDATE ATTENDANCE RECORDS
    // -----------------------------------------------

    final attendanceKeys =
        <String>[];

    for (final key in box.keys) {
      if (key
          .toString()
          .startsWith("class_")) {
        attendanceKeys.add(
          key.toString(),
        );
      }
    }

    int held = 0;
    int attended = 0;

    for (final key
        in attendanceKeys) {
      final data =
          box.get(key);

      if (data == null) {
        continue;
      }

      try {
        final record =
            ClassAttendance
                .fromMap(
          Map<String, dynamic>
              .from(data),
        );

        if (record.subject ==
            oldName) {
          final updatedRecord =
              ClassAttendance(
            date: record.date,
            subject: newName,
            classId:
                record.classId,
            status:
                record.status,
          );

          await box.put(
            key,
            updatedRecord
                .toMap(),
          );

          held++;

          if (record.status ==
              "present") {
            attended++;
          }
        }
      } catch (_) {
        // Ignore incompatible
        // old records.
      }
    }

    // -----------------------------------------------
    // MOVE ATTENDANCE TOTAL
    // -----------------------------------------------

    final oldTotals =
        getAttendance(
      oldName,
    );

    if (oldTotals != null) {
      await box.delete(
        oldName,
      );

      await saveAttendance(
        newName,
        held,
        attended,
      );
    }
  }

  // ==================================================
  // DELETE SUBJECT
  // ==================================================

  static Future<void> deleteSubject(
    String subject,
  ) async {
    // -----------------------------------------------
    // REMOVE FROM SUBJECT LIST
    // -----------------------------------------------

    final subjects =
        getSubjects();

    subjects.removeWhere(
      (item) =>
          item == subject,
    );

    await saveSubjects(
      subjects,
    );

    // -----------------------------------------------
    // REMOVE FROM WEEKLY TIMETABLE
    // -----------------------------------------------

    final timetable =
        getTimetable();

    final updatedTimetable =
        timetable
            .where(
              (entry) =>
                  entry.subject !=
                  subject,
            )
            .toList();

    await box.put(
      "timetable",
      updatedTimetable
          .map(
            (entry) =>
                entry.toMap(),
          )
          .toList(),
    );

    // -----------------------------------------------
    // REMOVE FROM DAY OVERRIDES
    // -----------------------------------------------

    final overrideKeys =
        <String>[];

    for (final key in box.keys) {
      if (key
          .toString()
          .startsWith(
            "day_override_",
          )) {
        overrideKeys.add(
          key.toString(),
        );
      }
    }

    for (final key
        in overrideKeys) {
      final date =
          key.replaceFirst(
        "day_override_",
        "",
      );

      final override =
          getDayOverride(
        date,
      );

      if (override ==
          null) {
        continue;
      }

      final updatedClasses =
          override.classes
              .where(
                (item) {
                  final entry =
                      TimetableEntry
                          .fromMap(
                    Map<String,
                        dynamic>.from(
                      item,
                    ),
                  );

                  return entry.subject !=
                      subject;
                },
              )
              .toList();

      // If nothing remains,
      // remove the override completely.
      if (updatedClasses.isEmpty) {
        await box.delete(
          "day_override_$date",
        );
      } else {
        await saveDayOverride(
          DayOverride(
            date: override.date,
            classes:
                updatedClasses,
          ),
        );
      }
    }

    // -----------------------------------------------
    // REMOVE ATTENDANCE RECORDS
    // -----------------------------------------------

    final attendanceKeys =
        <String>[];

    for (final key in box.keys) {
      if (key
          .toString()
          .startsWith("class_")) {
        attendanceKeys.add(
          key.toString(),
        );
      }
    }

    for (final key
        in attendanceKeys) {
      final data =
          box.get(key);

      if (data == null) {
        continue;
      }

      try {
        final record =
            ClassAttendance
                .fromMap(
          Map<String, dynamic>
              .from(data),
        );

        if (record.subject ==
            subject) {
          await box.delete(
            key,
          );
        }
      } catch (_) {
        // Ignore incompatible
        // old records.
      }
    }

    // -----------------------------------------------
    // REMOVE SUBJECT TOTAL
    // -----------------------------------------------

    await box.delete(
      subject,
    );
  }

  // ==================================================
  // RESET ALL DATA
  // ==================================================

  static Future<void>
      resetAllData() async {
    await box.clear();
  }

  // ==================================================
  // SUBJECT TOTALS
  // ==================================================

  static Future<void> saveAttendance(
    String subject,
    int held,
    int attended,
  ) async {
    await box.put(
      subject,
      {
        "held": held,
        "attended": attended,
      },
    );
  }

  static Map<String, dynamic>?
      getAttendance(
    String subject,
  ) {
    final data =
        box.get(subject);

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>
        .from(data);
  }

  // ==================================================
  // WEEKLY TIMETABLE
  // ==================================================

  static Future<void> saveTimetable(
    List<TimetableEntry>
        newTimetable,
  ) async {
    final oldTimetable =
        getTimetable();

    // -----------------------------------------------
    // FIND DATES THAT ALREADY HAVE ATTENDANCE
    // -----------------------------------------------

    final markedDates =
        <String>{};

    for (final key in box.keys) {
      if (!key
          .toString()
          .startsWith("class_")) {
        continue;
      }

      final data =
          box.get(key);

      if (data == null) {
        continue;
      }

      try {
        final record =
            ClassAttendance
                .fromMap(
          Map<String, dynamic>
              .from(data),
        );

        markedDates.add(
          record.date,
        );
      } catch (_) {
        // Ignore incompatible
        // old records.
      }
    }

    // -----------------------------------------------
    // FREEZE OLD TIMETABLE
    // -----------------------------------------------

    for (final dateString
        in markedDates) {
      final existingOverride =
          getDayOverride(
        dateString,
      );

      if (existingOverride !=
          null) {
        continue;
      }

      final date =
          DateTime.tryParse(
        dateString,
      );

      if (date == null) {
        continue;
      }

      final dayName =
          _dayName(
        date.weekday,
      );

      final oldClasses =
          oldTimetable
              .where(
                (entry) =>
                    entry.day ==
                    dayName,
              )
              .map(
                (entry) =>
                    entry.toMap(),
              )
              .toList();

      if (oldClasses.isEmpty) {
        continue;
      }

      await saveDayOverride(
        DayOverride(
          date: dateString,
          classes:
              oldClasses,
        ),
      );
    }

    // -----------------------------------------------
    // SAVE NEW WEEKLY TIMETABLE
    // -----------------------------------------------

    await box.put(
      "timetable",
      newTimetable
          .map(
            (entry) =>
                entry.toMap(),
          )
          .toList(),
    );
  }

  static List<TimetableEntry>
      getTimetable() {
    final data =
        box.get("timetable");

    if (data == null) {
      return [];
    }

    final entries =
        <TimetableEntry>[];

    bool needsMigration =
        false;

    for (final item
        in data as List) {
      final map =
          Map<String, dynamic>
              .from(item);

      if (map['id'] == null ||
          map['id']
              .toString()
              .isEmpty) {
        needsMigration = true;
      }

      entries.add(
        TimetableEntry
            .fromMap(map),
      );
    }

    if (needsMigration) {
      box.put(
        "timetable",
        entries
            .map(
              (entry) =>
                  entry.toMap(),
            )
            .toList(),
      );
    }

    return entries;
  }

  // ==================================================
  // DAY NAME
  // ==================================================

  static String _dayName(
    int weekday,
  ) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    return days[weekday - 1];
  }

  // ==================================================
  // CLASS ATTENDANCE
  // ==================================================

  static String _classKey(
    String date,
    String classId,
  ) {
    return "${date}_$classId";
  }

  static Future<void>
      saveClassAttendance(
    ClassAttendance attendance,
  ) async {
    final key =
        _classKey(
      attendance.date,
      attendance.classId,
    );

    await box.put(
      "class_$key",
      attendance.toMap(),
    );
  }

  static ClassAttendance?
      getClassAttendance(
    String date,
    String classId,
  ) {
    final key =
        _classKey(
      date,
      classId,
    );

    final data =
        box.get(
      "class_$key",
    );

    if (data == null) {
      return null;
    }

    return ClassAttendance
        .fromMap(
      Map<String, dynamic>
          .from(data),
    );
  }

  static Future<void>
      removeClassAttendance(
    String date,
    String classId,
  ) async {
    final key =
        _classKey(
      date,
      classId,
    );

    await box.delete(
      "class_$key",
    );
  }

  // ==================================================
  // REMOVE ATTENDANCE + UPDATE TOTALS
  // ==================================================

  static Future<void>
      removeClassAttendanceAndUpdateTotals(
    String date,
    String classId,
    String subject,
  ) async {
    await removeClassAttendance(
      date,
      classId,
    );

    final records =
        getAllClassAttendance(
      subject,
    );

    final held =
        records.length;

    final attended =
        records
            .where(
              (record) =>
                  record.status ==
                  "present",
            )
            .length;

    await saveAttendance(
      subject,
      held,
      attended,
    );
  }

  // ==================================================
  // GET ALL ATTENDANCE FOR SUBJECT
  // ==================================================

  static List<ClassAttendance>
      getAllClassAttendance(
    String subject,
  ) {
    final records =
        <ClassAttendance>[];

    for (final key in box.keys) {
      if (!key
          .toString()
          .startsWith("class_")) {
        continue;
      }

      final data =
          box.get(key);

      if (data == null) {
        continue;
      }

      try {
        final record =
            ClassAttendance
                .fromMap(
          Map<String, dynamic>
              .from(data),
        );

        if (record.subject ==
            subject) {
          records.add(
            record,
          );
        }
      } catch (_) {
        // Ignore incompatible
        // old records.
      }
    }

    return records;
  }

  // ==================================================
  // GET ALL ATTENDANCE FOR DATE
  // ==================================================

  static List<ClassAttendance>
      getAllClassAttendanceForDate(
    String date,
  ) {
    final records =
        <ClassAttendance>[];

    for (final key in box.keys) {
      if (!key
          .toString()
          .startsWith("class_")) {
        continue;
      }

      final data =
          box.get(key);

      if (data == null) {
        continue;
      }

      try {
        final record =
            ClassAttendance
                .fromMap(
          Map<String, dynamic>
              .from(data),
        );

        if (record.date ==
            date) {
          records.add(
            record,
          );
        }
      } catch (_) {
        // Ignore incompatible
        // old records.
      }
    }

    return records;
  }

  // ==================================================
  // DAY OVERRIDES
  // ==================================================

  static Future<void>
      saveDayOverride(
    DayOverride override,
  ) async {
    await box.put(
      "day_override_${override.date}",
      override.toMap(),
    );
  }

  static DayOverride?
      getDayOverride(
    String date,
  ) {
    final data =
        box.get(
      "day_override_$date",
    );

    if (data == null) {
      return null;
    }

    final override =
        DayOverride.fromMap(
      Map<String, dynamic>
          .from(data),
    );

    // -----------------------------------------------
    // MIGRATE OLD OVERRIDE CLASSES
    // -----------------------------------------------

    bool needsMigration =
        false;

    final updatedClasses =
        <Map<String, dynamic>>[];

    for (final item
        in override.classes) {
      final map =
          Map<String, dynamic>
              .from(item);

      if (map['id'] == null ||
          map['id']
              .toString()
              .isEmpty) {
        final entry =
            TimetableEntry
                .fromMap(map);

        updatedClasses.add(
          entry.toMap(),
        );

        needsMigration = true;
      } else {
        updatedClasses.add(
          map,
        );
      }
    }

    if (needsMigration) {
      final updatedOverride =
          DayOverride(
        date: override.date,
        classes:
            updatedClasses,
      );

      box.put(
        "day_override_$date",
        updatedOverride.toMap(),
      );

      return updatedOverride;
    }

    return override;
  }
}