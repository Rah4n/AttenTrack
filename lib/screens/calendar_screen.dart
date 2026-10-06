import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'timetable_screen.dart';
import '../database/hive_helper.dart';
import '../models/timetable_entry.dart';
import '../models/class_attendance.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() =>
      _CalendarScreenState();
}

class _CalendarScreenState
    extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();

  // --------------------------------------------------
  // DATE STRING
  // --------------------------------------------------

  String _dateString(DateTime date) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // --------------------------------------------------
  // DAY NAME
  // --------------------------------------------------

  String _dayName(DateTime date) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    return days[date.weekday - 1];
  }

  // --------------------------------------------------
  // GET CLASSES FOR DATE
  // --------------------------------------------------

  List<TimetableEntry> _classesForDate(
    DateTime date,
  ) {
    final dateString = _dateString(date);

    final override =
        HiveHelper.getDayOverride(dateString);

    if (override != null) {
      return override.classes
          .map(
            (item) => TimetableEntry.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    return HiveHelper.getTimetable()
        .where(
          (entry) =>
              entry.day == _dayName(date),
        )
        .toList();
  }

  // --------------------------------------------------
  // GET ATTENDANCE FOR CLASS
  // --------------------------------------------------

  ClassAttendance? _attendanceForClass(
    DateTime date,
    TimetableEntry entry,
  ) {
    return HiveHelper.getClassAttendance(
      _dateString(date),
      entry.id,
    );
  }

  // --------------------------------------------------
  // ATTENDANCE DOT
  // --------------------------------------------------

  Widget _buildDot(
    ClassAttendance? attendance,
  ) {
    Color color;

    if (attendance == null) {
      color = Colors.grey;
    } else if (attendance.status == "present") {
      color = Colors.green;
    } else {
      color = Colors.red;
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // --------------------------------------------------
  // 3 DOTS TOP + 3 DOTS BOTTOM
  // --------------------------------------------------

  Widget _buildAttendanceDots(
    DateTime date,
  ) {
    final classes = _classesForDate(date);

    if (classes.isEmpty) {
      return const SizedBox(
        height: 17,
      );
    }

    final visibleClasses =
        classes.take(6).toList();

    final topDots =
        visibleClasses.take(3).toList();

    final bottomDots =
        visibleClasses.skip(3).take(3).toList();

    return SizedBox(
      height: 17,
      width: 32,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 7,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: topDots.map(
                (entry) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    child: _buildDot(
                      _attendanceForClass(
                        date,
                        entry,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),

          const SizedBox(height: 2),

          SizedBox(
            height: 7,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: bottomDots.map(
                (entry) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    child: _buildDot(
                      _attendanceForClass(
                        date,
                        entry,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FIXED DATE BOX
  // --------------------------------------------------

  Widget _buildDateBox(
    BuildContext context,
    DateTime day, {
    bool selected = false,
    bool today = false,
    bool outside = false,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final backgroundColor = selected
        ? colorScheme.primary
        : Theme.of(context).cardColor;

    final borderColor = selected || today
        ? colorScheme.primary
        : Theme.of(context)
            .dividerColor
            .withOpacity(0.5);

    return Center(
      child: SizedBox(
        width: 48,
        height: 68,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width:
                  selected || today ? 1.5 : 1,
            ),
            boxShadow: [
              if (!selected)
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.04),
                  blurRadius: 3,
                  offset:
                      const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                "${day.day}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      selected || today
                          ? FontWeight.bold
                          : FontWeight.normal,
                  color: outside
                      ? Colors.grey
                      : selected
                          ? colorScheme
                              .onPrimary
                          : null,
                ),
              ),

              const SizedBox(height: 5),

              _buildAttendanceDots(day),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // OPEN DAY TIMETABLE
  // --------------------------------------------------

  Future<void> openDayTimetable(
    DateTime date,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TimetableScreen(
          date: date,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      selectedDate = date;
      focusedDate = date;
    });
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
      ),

      body: TableCalendar(
        firstDay: DateTime(2025),
        lastDay: DateTime(2030),

        focusedDay: focusedDate,

        // Same height for every row.
        rowHeight: 88,

        headerStyle:
            const HeaderStyle(
          titleCentered: false,
          formatButtonVisible: true,
          formatButtonShowsNext: false,
        ),

        daysOfWeekStyle:
            const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontWeight:
                FontWeight.w500,
            fontSize: 15,
          ),
          weekendStyle: TextStyle(
            fontWeight:
                FontWeight.w500,
            fontSize: 15,
          ),
        ),

        selectedDayPredicate: (day) {
          return isSameDay(
            selectedDate,
            day,
          );
        },

        onDaySelected: (
          selectedDay,
          focusedDay,
        ) {
          setState(() {
            selectedDate =
                selectedDay;
            focusedDate =
                focusedDay;
          });

          openDayTimetable(
            selectedDay,
          );
        },

        onPageChanged: (
          focusedDay,
        ) {
          setState(() {
            focusedDate =
                focusedDay;
          });
        },

        calendarBuilders:
            CalendarBuilders(
          defaultBuilder: (
            context,
            day,
            focusedDay,
          ) {
            return _buildDateBox(
              context,
              day,
            );
          },

          todayBuilder: (
            context,
            day,
            focusedDay,
          ) {
            return _buildDateBox(
              context,
              day,
              today: true,
            );
          },

          selectedBuilder: (
            context,
            day,
            focusedDay,
          ) {
            return _buildDateBox(
              context,
              day,
              selected: true,
            );
          },

          outsideBuilder: (
            context,
            day,
            focusedDay,
          ) {
            return _buildDateBox(
              context,
              day,
              outside: true,
            );
          },
        ),
      ),
    );
  }
}