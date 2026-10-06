import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../models/class_attendance.dart';
import '../database/hive_helper.dart';
import 'edit_day_screen.dart';

class TimetableScreen extends StatefulWidget {
  final DateTime date;

  const TimetableScreen({
    super.key,
    required this.date,
  });

  @override
  State<TimetableScreen> createState() =>
      _TimetableScreenState();
}

class _TimetableScreenState
    extends State<TimetableScreen> {
  List<TimetableEntry> timetable = [];

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  String _dateString() {
    return "${widget.date.year}-"
        "${widget.date.month.toString().padLeft(2, '0')}-"
        "${widget.date.day.toString().padLeft(2, '0')}";
  }

  String _getDayName(int weekday) {
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

  void loadTimetable() {
    final date = _dateString();

    final override =
        HiveHelper.getDayOverride(date);

    List<TimetableEntry> entries;

    if (override != null) {
      entries = override.classes
          .map(
            (item) => TimetableEntry.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } else {
      entries = HiveHelper.getTimetable()
          .where(
            (entry) =>
                entry.day ==
                _getDayName(
                  widget.date.weekday,
                ),
          )
          .toList();
    }

    if (!mounted) return;

    setState(() {
      timetable = entries;
    });
  }

  Future<void> showClassAttendanceDialog(
    TimetableEntry entry,
  ) async {
    final date = _dateString();

    final existing =
        HiveHelper.getClassAttendance(
      date,
      entry.id,
    );

    String? status = existing?.status;

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(entry.subject),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Text(
                    "Mark attendance",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child:
                            ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              status =
                                  status ==
                                          "present"
                                      ? null
                                      : "present";
                            });
                          },
                          icon: const Icon(
                            Icons.check,
                          ),
                          label:
                              const Text(
                            "Present",
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                status ==
                                        "present"
                                    ? Colors
                                        .green
                                    : null,
                            foregroundColor:
                                status ==
                                        "present"
                                    ? Colors
                                        .white
                                    : null,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child:
                            ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              status =
                                  status ==
                                          "absent"
                                      ? null
                                      : "absent";
                            });
                          },
                          icon: const Icon(
                            Icons.close,
                          ),
                          label:
                              const Text(
                            "Absent",
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                status ==
                                        "absent"
                                    ? Colors
                                        .red
                                    : null,
                            foregroundColor:
                                status ==
                                        "absent"
                                    ? Colors
                                        .white
                                    : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  if (status == null)
                    const Text(
                      "Unmarked",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child:
                      const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (status == null) {
                      await HiveHelper
                          .removeClassAttendance(
                        date,
                        entry.id,
                      );
                    } else {
                      await HiveHelper
                          .saveClassAttendance(
                        ClassAttendance(
                          date: date,
                          classId: entry.id,
                          subject:
                              entry.subject,
                          status: status!,
                        ),
                      );
                    }

                    final records =
                        HiveHelper
                            .getAllClassAttendance(
                      entry.subject,
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

                    await HiveHelper
                        .saveAttendance(
                      entry.subject,
                      held,
                      attended,
                    );

                    if (!dialogContext
                        .mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Widget _buildAttendanceStatus(
    TimetableEntry entry,
  ) {
    final date = _dateString();

    final attendance =
        HiveHelper.getClassAttendance(
      date,
      entry.id,
    );

    if (attendance == null) {
      return const Icon(
        Icons.circle,
        size: 14,
        color: Colors.grey,
      );
    }

    if (attendance.status ==
        "present") {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 30,
      );
    }

    return const Icon(
      Icons.cancel,
      color: Colors.red,
      size: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayName =
        _getDayName(
      widget.date.weekday,
    );

    final dayTimetable = timetable
        .where(
          (entry) =>
              entry.day == dayName,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(dayName),
        centerTitle: true,
      ),

      body: dayTimetable.isEmpty
          ? const Center(
              child: Text(
                "No classes scheduled",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount:
                  dayTimetable.length,
              itemBuilder:
                  (context, index) {
                final entry =
                    dayTimetable[index];

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        "${index + 1}",
                      ),
                    ),

                    title: Text(
                      entry.subject,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    trailing:
                        _buildAttendanceStatus(
                      entry,
                    ),

                    onTap: () async {
                      await showClassAttendanceDialog(
                        entry,
                      );

                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                );
              },
            ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final changed =
              await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditDayScreen(
                date: widget.date,
                classes:
                    dayTimetable,
              ),
            ),
          );

          if (changed == true &&
              mounted) {
            loadTimetable();
          }
        },
        icon: const Icon(
          Icons.edit_note,
        ),
        label: const Text(
          "Edit This Day",
        ),
      ),
    );
  }
}