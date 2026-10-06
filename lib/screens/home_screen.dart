import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../database/hive_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Subject> subjects = [];

  // ==================================================
  // LOAD SUBJECTS + ATTENDANCE
  // ==================================================

  Future<void> loadData() async {
    final savedSubjects =
        HiveHelper.getSubjects();

    final loadedSubjects =
        <Subject>[];

    for (final name in savedSubjects) {
      final subject =
          Subject(name: name);

      final data =
          HiveHelper.getAttendance(name);

      if (data != null) {
        subject.held =
            data["held"] ?? 0;

        subject.attended =
            data["attended"] ?? 0;
      }

      loadedSubjects.add(subject);
    }

    if (!mounted) return;

    setState(() {
      subjects = loadedSubjects;
    });
  }

  // ==================================================
  // INIT
  // ==================================================

  @override
  void initState() {
    super.initState();

    loadData();
  }

  // ==================================================
  // REFRESH WHEN RETURNING TO HOME
  // ==================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // This makes Home reload when the screen becomes
    // active again after navigating from Settings,
    // Timetable, Calendar, etc.
  }

  // ==================================================
  // OVERALL ATTENDANCE
  // ==================================================

  double get overallAttendance {
    int held = 0;
    int attended = 0;

    for (final subject in subjects) {
      held += subject.held;
      attended += subject.attended;
    }

    if (held == 0) {
      return 0;
    }

    return (attended / held) * 100;
  }

  // ==================================================
  // OVERALL HELD
  // ==================================================

  int get overallHeld {
    int held = 0;

    for (final subject in subjects) {
      held += subject.held;
    }

    return held;
  }

  // ==================================================
  // OVERALL PRESENT
  // ==================================================

  int get overallPresent {
    int present = 0;

    for (final subject in subjects) {
      present += subject.attended;
    }

    return present;
  }

  // ==================================================
  // OVERALL ABSENT
  // ==================================================

  int get overallAbsent {
    return overallHeld -
        overallPresent;
  }

  // ==================================================
  // CLASSES CAN MISS
  // ==================================================

  int overallClassesCanMiss() {
    int held = 0;
    int attended = 0;

    for (final subject in subjects) {
      held += subject.held;
      attended += subject.attended;
    }

    if (held == 0) {
      return 0;
    }

    int miss = 0;

    while (
      attended /
              (held + miss) >=
          0.75
    ) {
      miss++;
    }

    return miss - 1;
  }

  // ==================================================
  // CLASSES NEEDED
  // ==================================================

  int overallClassesNeeded() {
    int held = 0;
    int attended = 0;

    for (final subject in subjects) {
      held += subject.held;
      attended += subject.attended;
    }

    if (held == 0) {
      return 0;
    }

    int need = 0;

    while (
      (attended + need) /
              (held + need) <
          0.75
    ) {
      need++;
    }

    return need;
  }

  // ==================================================
  // OVERALL STAT
  // ==================================================

  Widget _buildOverallStat(
    String label,
    int value,
  ) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==================================================
  // ABOUT
  // ==================================================

  void showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            const Text("AttenTrack"),

        content: const Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 60,
              color: Colors.blue,
            ),

            SizedBox(
              height: 12,
            ),

            Text(
              "Version 1.0",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(
              height: 12,
            ),

            Text(
              "A simple attendance tracker "
              "with attendance prediction.",
              textAlign:
                  TextAlign.center,
            ),

            SizedBox(
              height: 16,
            ),

            Text(
              "Developed by\n"
              "Rahan Ali Ahamed",
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),

            child:
                const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("AttenTrack"),

        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
            ),

            onPressed:
                showAboutDialog,

            tooltip: "About",
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadData,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: [
            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // OVERALL ATTENDANCE
            // ==================================================

            Card(
              margin:
                  const EdgeInsets.all(15),

              elevation: 5,

              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  children: [
                    const Text(
                      "Overall Attendance",
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Text(
                      "${overallAttendance.toStringAsFixed(1)}%",

                      style: TextStyle(
                        fontSize: 40,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            overallAttendance >=
                                    75
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceEvenly,

                      children: [
                        _buildOverallStat(
                          "Held",
                          overallHeld,
                        ),

                        _buildOverallStat(
                          "Present",
                          overallPresent,
                        ),

                        _buildOverallStat(
                          "Absent",
                          overallAbsent,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    if (overallAttendance >=
                        75)
                      Text(
                        "🟢 You can skip "
                        "${overallClassesCanMiss()} "
                        "more classes",

                        style:
                            const TextStyle(
                          color:
                              Colors.green,

                          fontWeight:
                              FontWeight.bold,

                          fontSize: 16,
                        ),
                      )
                    else
                      Text(
                        "🔴 Attend the next "
                        "${overallClassesNeeded()} "
                        "classes to reach 75%",

                        style:
                            const TextStyle(
                          color:
                              Colors.red,

                          fontWeight:
                              FontWeight.bold,

                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // SUBJECTS
            // ==================================================

            if (subjects.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.all(30),

                child: Center(
                  child: Text(
                    "No subjects added yet.\n"
                    "Add subjects from Settings.",

                    textAlign:
                        TextAlign.center,

                    style: TextStyle(
                      fontSize: 16,
                      color:
                          Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ...subjects.map(
                (subject) {
                  return Card(
                    margin:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),

                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        15,
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          // --------------------------------
                          // SUBJECT NAME
                          // --------------------------------

                          Text(
                            subject.name,

                            style:
                                const TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          // --------------------------------
                          // HELD
                          // --------------------------------

                          Text(
                            "Held : "
                            "${subject.held}",
                          ),

                          // --------------------------------
                          // PRESENT
                          // --------------------------------

                          Text(
                            "Present : "
                            "${subject.attended}",
                          ),

                          // --------------------------------
                          // ABSENT
                          // --------------------------------

                          Text(
                            "Absent : "
                            "${subject.held - subject.attended}",
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          // --------------------------------
                          // PERCENTAGE
                          // --------------------------------

                          Text(
                            "Attendance : "
                            "${subject.percentage.toStringAsFixed(1)}%",

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          // --------------------------------
                          // PROGRESS BAR
                          // --------------------------------

                          LinearProgressIndicator(
                            value:
                                subject.percentage /
                                    100,

                            minHeight: 10,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),

                            color:
                                subject.percentage >=
                                        75
                                    ? Colors.green
                                    : Colors.red,
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          // --------------------------------
                          // PREDICTION
                          // --------------------------------

                          if (subject.percentage >=
                              75)
                            Text(
                              "🟢 Can miss: "
                              "${subject.classesCanMiss(0.75)} "
                              "classes",

                              style:
                                  const TextStyle(
                                color:
                                    Colors.green,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            )
                          else
                            Text(
                              "🔴 Need: "
                              "${subject.classesNeeded(0.75)} "
                              "classes to reach 75%",

                              style:
                                  const TextStyle(
                                color:
                                    Colors.red,

                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}