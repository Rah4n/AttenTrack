import 'package:flutter/material.dart';
import '../models/class_attendance.dart';
import '../database/hive_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime selectedMonth = DateTime.now();

  int monthlyHeld() {
    int held = 0;

    for (final key in HiveHelper.box.keys) {
      if (key.toString().startsWith("class_")) {
        final data = HiveHelper.box.get(key);

        if (data != null) {
          final record = ClassAttendance.fromMap(
            Map<String, dynamic>.from(data),
          );

          final date = DateTime.tryParse(record.date);

          if (date != null &&
              date.year == selectedMonth.year &&
              date.month == selectedMonth.month) {
            held++;
          }
        }
      }
    }

    return held;
  }

  int monthlyPresent() {
    int present = 0;

    for (final key in HiveHelper.box.keys) {
      if (key.toString().startsWith("class_")) {
        final data = HiveHelper.box.get(key);

        if (data != null) {
          final record = ClassAttendance.fromMap(
            Map<String, dynamic>.from(data),
          );

          final date = DateTime.tryParse(record.date);

          if (date != null &&
              date.year == selectedMonth.year &&
              date.month == selectedMonth.month &&
              record.status == "present") {
            present++;
          }
        }
      }
    }

    return present;
  }

  int monthlyAbsent() {
    return monthlyHeld() - monthlyPresent();
  }

  double get monthlyAttendance {
    final held = monthlyHeld();
    final present = monthlyPresent();

    if (held == 0) return 0;

    return (present / held) * 100;
  }

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });
  }

  String get monthName {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${months[selectedMonth.month - 1]} "
        "${selectedMonth.year}";
  }

  Widget buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendance = monthlyAttendance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Monthly Attendance",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: previousMonth,
                          icon: const Icon(
                            Icons.chevron_left,
                          ),
                        ),

                        Text(
                          monthName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          onPressed: nextMonth,
                          icon: const Icon(
                            Icons.chevron_right,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "${attendance.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: attendance >= 75
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        buildStat(
                          "Held",
                          monthlyHeld(),
                        ),
                        buildStat(
                          "Present",
                          monthlyPresent(),
                        ),
                        buildStat(
                          "Absent",
                          monthlyAbsent(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    LinearProgressIndicator(
                      value: attendance / 100,
                      minHeight: 12,
                      borderRadius:
                          BorderRadius.circular(10),
                      color: attendance >= 75
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}