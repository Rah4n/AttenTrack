import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../database/hive_helper.dart';
import '../models/day_override.dart';

class EditDayScreen extends StatefulWidget {
  final DateTime date;
  final List<TimetableEntry> classes;

  const EditDayScreen({
    super.key,
    required this.date,
    required this.classes,
  });

  @override
  State<EditDayScreen> createState() =>
      _EditDayScreenState();
}

class _EditDayScreenState
    extends State<EditDayScreen> {
  late List<TimetableEntry> dayClasses;

  // ==================================================
  // INIT
  // ==================================================

  @override
  void initState() {
    super.initState();

    dayClasses = List.from(
      widget.classes,
    );
  }

  // ==================================================
  // DATE STRING
  // ==================================================

  String _dateString() {
    return "${widget.date.year}-"
        "${widget.date.month.toString().padLeft(2, '0')}-"
        "${widget.date.day.toString().padLeft(2, '0')}";
  }

  // ==================================================
  // DAY NAME
  // ==================================================

  String _dayName(
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
  // ADD / EDIT CLASS
  // ==================================================

  Future<void> showClassDialog({
    int? index,
  }) async {
    // -----------------------------------------------
    // LOAD CURRENT SUBJECTS FROM HIVE
    // -----------------------------------------------

    final subjects =
        HiveHelper.getSubjects();

    // No subjects available
    if (subjects.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "No subjects available. "
            "Add a subject in Settings first.",
          ),
        ),
      );

      return;
    }

    final existing =
        index == null
            ? null
            : dayClasses[index];

    // -----------------------------------------------
    // SELECTED SUBJECT
    // -----------------------------------------------

    String selectedSubject;

    if (existing != null &&
        subjects.contains(
          existing.subject,
        )) {
      selectedSubject =
          existing.subject;
    } else {
      selectedSubject =
          subjects.first;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                index == null
                    ? "Add Class"
                    : "Edit Class",
              ),

              content:
                  DropdownButtonFormField<
                      String>(
                value: selectedSubject,

                decoration:
                    const InputDecoration(
                  labelText: "Subject",
                  border:
                      OutlineInputBorder(),
                ),

                items: subjects.map(
                  (subject) {
                    return DropdownMenuItem<
                        String>(
                      value: subject,
                      child: Text(subject),
                    );
                  },
                ).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setDialogState(() {
                    selectedSubject =
                        value;
                  });
                },
              ),

              actions: [
                // ---------------------------------------
                // CANCEL
                // ---------------------------------------

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text("Cancel"),
                ),

                // ---------------------------------------
                // SAVE / ADD
                // ---------------------------------------

                ElevatedButton(
                  onPressed: () async {
                    // ===================================
                    // ADD NEW CLASS
                    // ===================================

                    if (index == null) {
                      final newEntry =
                          TimetableEntry(
                        day: _dayName(
                          widget.date.weekday,
                        ),
                        subject:
                            selectedSubject,
                      );

                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        dayClasses.add(
                          newEntry,
                        );
                      });
                    }

                    // ===================================
                    // EDIT EXISTING CLASS
                    // ===================================

                    else {
                      final oldEntry =
                          dayClasses[index];

                      // ---------------------------------
                      // SUBJECT CHANGED
                      // ---------------------------------

                      if (oldEntry.subject !=
                          selectedSubject) {
                        await HiveHelper
                            .removeClassAttendanceAndUpdateTotals(
                          _dateString(),
                          oldEntry.id,
                          oldEntry.subject,
                        );
                      }

                      // ---------------------------------
                      // KEEP SAME CLASS ID
                      // ---------------------------------
                      //
                      // This is VERY important.
                      //
                      // The attendance belongs to the
                      // timetable class ID.
                      //
                      // Keeping the ID prevents the
                      // wrong class from being affected.
                      // ---------------------------------

                      final updatedEntry =
                          TimetableEntry(
                        id: oldEntry.id,
                        day: _dayName(
                          widget.date.weekday,
                        ),
                        subject:
                            selectedSubject,
                      );

                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        dayClasses[index] =
                            updatedEntry;
                      });
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                    );
                  },

                  child: Text(
                    index == null
                        ? "Add"
                        : "Save",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================================================
  // SAVE DAY
  // ==================================================

  Future<void> saveChanges() async {
    final override =
        DayOverride(
      date: _dateString(),
      classes: dayClasses.map(
        (entry) {
          return entry.toMap();
        },
      ).toList(),
    );

    await HiveHelper.saveDayOverride(
      override,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  // ==================================================
  // DELETE CLASS
  // ==================================================

  Future<void> deleteClass(
    int index,
  ) async {
    final entry =
        dayClasses[index];

    // Remove attendance belonging
    // specifically to this class.
    await HiveHelper
        .removeClassAttendanceAndUpdateTotals(
      _dateString(),
      entry.id,
      entry.subject,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      dayClasses.removeAt(index);
    });
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
        title: const Text(
          "Edit This Day",
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
            ),
            tooltip: "Save",
            onPressed: saveChanges,
          ),
        ],
      ),

      // ==================================================
      // BODY
      // ==================================================

      body: dayClasses.isEmpty
          ? const Center(
              child: Text(
                "No classes for this day",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )
          : ReorderableListView.builder(
              padding:
                  const EdgeInsets.all(12),

              itemCount:
                  dayClasses.length,

              // ------------------------------------------
              // REORDER
              // ------------------------------------------

              onReorder:
                  (oldIndex, newIndex) {
                setState(() {
                  if (newIndex >
                      oldIndex) {
                    newIndex--;
                  }

                  final item =
                      dayClasses.removeAt(
                    oldIndex,
                  );

                  dayClasses.insert(
                    newIndex,
                    item,
                  );
                });
              },

              // ------------------------------------------
              // CLASS CARD
              // ------------------------------------------

              itemBuilder:
                  (context, index) {
                final entry =
                    dayClasses[index];

                return Card(
                  key: ValueKey(
                    entry.id,
                  ),

                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),

                  child: ListTile(
                    // CLASS NUMBER
                    leading:
                        CircleAvatar(
                      child: Text(
                        "${index + 1}",
                      ),
                    ),

                    // SUBJECT
                    title: Text(
                      entry.subject,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    // ACTIONS
                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        // --------------------------------
                        // EDIT
                        // --------------------------------

                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                          ),
                          tooltip:
                              "Edit Class",
                          onPressed: () {
                            showClassDialog(
                              index: index,
                            );
                          },
                        ),

                        // --------------------------------
                        // DELETE
                        // --------------------------------

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          tooltip:
                              "Delete Class",
                          onPressed: () {
                            deleteClass(
                              index,
                            );
                          },
                        ),

                        // --------------------------------
                        // DRAG
                        // --------------------------------

                        const Icon(
                          Icons.drag_handle,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // ==================================================
      // ADD CLASS
      // ==================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          showClassDialog();
        },

        icon: const Icon(
          Icons.add,
        ),

        label: const Text(
          "Add Class",
        ),
      ),
    );
  }
}