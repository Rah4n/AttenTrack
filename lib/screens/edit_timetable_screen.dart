import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../database/hive_helper.dart';

class EditTimetableScreen extends StatefulWidget {
  const EditTimetableScreen({super.key});

  @override
  State<EditTimetableScreen> createState() =>
      _EditTimetableScreenState();
}

class _EditTimetableScreenState
    extends State<EditTimetableScreen> {
  List<TimetableEntry> timetable = [];
  List<String> subjects = [];

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==================================================
  // LOAD DATA
  // ==================================================

  void _loadData() {
    final savedTimetable =
        HiveHelper.getTimetable();

    final savedSubjects =
        HiveHelper.getSubjects();

    if (!mounted) return;

    setState(() {
      timetable = savedTimetable;
      subjects = savedSubjects;
    });
  }

  // ==================================================
  // REFRESH DATA
  // ==================================================

  void _refreshData() {
    final latestTimetable =
        HiveHelper.getTimetable();

    final latestSubjects =
        HiveHelper.getSubjects();

    if (!mounted) return;

    setState(() {
      timetable = latestTimetable;
      subjects = latestSubjects;
    });
  }

  // ==================================================
  // GET CLASSES FOR DAY
  // ==================================================

  List<TimetableEntry> classesForDay(
    String day,
  ) {
    return timetable
        .where(
          (entry) => entry.day == day,
        )
        .toList();
  }

  // ==================================================
  // OPEN DAY
  // ==================================================

  Future<void> openDay(
    String day,
  ) async {
    // Always get latest data from Hive.
    final latestTimetable =
        HiveHelper.getTimetable();

    final latestSubjects =
        HiveHelper.getSubjects();

    final dayClasses = latestTimetable
        .where(
          (entry) => entry.day == day,
        )
        .toList();

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DayTimetableEditor(
          day: day,
          classes: dayClasses,
          subjects: latestSubjects,
        ),
      ),
    );

    if (!mounted) return;

    // Refresh after coming back.
    _refreshData();
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
          "Timetable",
        ),
        centerTitle: true,
      ),

      body: ListView.builder(
        padding:
            const EdgeInsets.all(12),

        itemCount:
            days.length,

        itemBuilder:
            (context, index) {
          final day =
              days[index];

          final classes =
              classesForDay(day);

          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 12,
            ),

            child: ListTile(
              leading:
                  CircleAvatar(
                child: Text(
                  "${index + 1}",
                ),
              ),

              title: Text(
                day,
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              subtitle: Text(
                classes.isEmpty
                    ? "No classes"
                    : "${classes.length} "
                      "class${classes.length == 1 ? '' : 'es'}",
              ),

              trailing:
                  const Icon(
                Icons.chevron_right,
              ),

              onTap: () {
                openDay(day);
              },
            ),
          );
        },
      ),
    );
  }
}

// ==================================================
// DAY TIMETABLE EDITOR
// ==================================================

class DayTimetableEditor
    extends StatefulWidget {
  final String day;
  final List<TimetableEntry> classes;
  final List<String> subjects;

  const DayTimetableEditor({
    super.key,
    required this.day,
    required this.classes,
    required this.subjects,
  });

  @override
  State<DayTimetableEditor>
      createState() =>
          _DayTimetableEditorState();
}

class _DayTimetableEditorState
    extends State<DayTimetableEditor> {
  late List<TimetableEntry>
      dayClasses;

  late List<String>
      subjects;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    dayClasses =
        List<TimetableEntry>.from(
      widget.classes,
    );

    subjects =
        List<String>.from(
      widget.subjects,
    );
  }

  // ==================================================
  // SAVE DAY
  // ==================================================

  Future<bool> _saveDay() async {
    if (saving) {
      return false;
    }

    if (mounted) {
      setState(() {
        saving = true;
      });
    }

    try {
      // Get the complete timetable.
      final allClasses =
          HiveHelper.getTimetable();

      // Remove only this day's old classes.
      allClasses.removeWhere(
        (entry) =>
            entry.day == widget.day,
      );

      // Add the current edited classes.
      allClasses.addAll(
        dayClasses,
      );

      // Save the complete timetable.
      await HiveHelper.saveTimetable(
        allClasses,
      );

      return true;
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ==================================================
  // AUTO SAVE AND GO BACK
  // ==================================================

  Future<void> saveAndGoBack() async {
    if (saving) {
      return;
    }

    final success =
        await _saveDay();

    if (!mounted || !success) {
      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  // ==================================================
  // ADD CLASS
  // ==================================================

  Future<void> addClass() async {
    // Get latest subjects from Settings.
    subjects =
        HiveHelper.getSubjects();

    if (subjects.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Add subjects in Settings → Edit Course first",
          ),
        ),
      );

      return;
    }

    String? selectedSubject;

    final added =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title:
                  const Text(
                "Add Class",
              ),

              content:
                  DropdownButtonFormField<
                      String>(
                value:
                    selectedSubject,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Subject",
                  border:
                      OutlineInputBorder(),
                ),

                items: subjects
                    .map(
                      (subject) {
                    return DropdownMenuItem<
                        String>(
                      value:
                          subject,
                      child:
                          Text(subject),
                    );
                  },
                ).toList(),

                onChanged:
                    (value) {
                  setDialogState(() {
                    selectedSubject =
                        value;
                  });
                },
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
                      const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (selectedSubject ==
                        null) {
                      return;
                    }

                    final newClass =
                        TimetableEntry(
                      day:
                          widget.day,
                      subject:
                          selectedSubject!,
                    );

                    setState(() {
                      dayClasses.add(
                        newClass,
                      );
                    });

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },

                  child:
                      const Text(
                    "Add",
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (added == true &&
        mounted) {
      setState(() {});
    }
  }

  // ==================================================
  // EDIT CLASS
  // ==================================================

  Future<void> editClass(
    int index,
  ) async {
    // Get latest subjects.
    final latestSubjects =
        HiveHelper.getSubjects();

    if (latestSubjects.isEmpty) {
      return;
    }

    subjects =
        List<String>.from(
      latestSubjects,
    );

    final oldEntry =
        dayClasses[index];

    String selectedSubject =
        oldEntry.subject;

    // If the old subject was removed
    // from Settings, keep it temporarily
    // so the existing timetable doesn't break.
    if (!subjects.contains(
      selectedSubject,
    )) {
      subjects.insert(
        0,
        selectedSubject,
      );
    }

    final edited =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title:
                  const Text(
                "Edit Class",
              ),

              content:
                  DropdownButtonFormField<
                      String>(
                value:
                    selectedSubject,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Subject",
                  border:
                      OutlineInputBorder(),
                ),

                items: subjects
                    .map(
                      (subject) {
                    return DropdownMenuItem<
                        String>(
                      value:
                          subject,
                      child:
                          Text(subject),
                    );
                  },
                ).toList(),

                onChanged:
                    (value) {
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
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child:
                      const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    final updatedEntry =
                        TimetableEntry(
                      // KEEP SAME ID
                      // so attendance stays linked.
                      id:
                          oldEntry.id,

                      day:
                          widget.day,

                      subject:
                          selectedSubject,
                    );

                    setState(() {
                      dayClasses[index] =
                          updatedEntry;
                    });

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },

                  child:
                      const Text(
                    "Save",
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (edited == true &&
        mounted) {
      setState(() {});
    }
  }

  // ==================================================
  // DELETE CLASS
  // ==================================================

  Future<void> deleteClass(
    int index,
  ) async {
    final entry =
        dayClasses[index];

    final confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            "Delete Class",
          ),

          content: Text(
            "Remove ${entry.subject} from ${widget.day}?",
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
                  const Text(
                "Cancel",
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),

              child:
                  const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    // Remove the class from the local list.
    setState(() {
      dayClasses.removeAt(
        index,
      );
    });

    // Attendance for the old class
    // remains associated with its ID.
    // The class itself will be removed
    // from timetable when Back is pressed.
  }

  // ==================================================
  // REORDER
  // ==================================================

  void reorderClasses(
    int oldIndex,
    int newIndex,
  ) {
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
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (
        didPop,
        result,
      ) async {
        if (didPop ||
            saving) {
          return;
        }

        // Automatically save before
        // going back.
        await saveAndGoBack();
      },

      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.day),

          centerTitle: true,
        ),

        body: dayClasses.isEmpty
            ? const Center(
                child: Text(
                  "No classes added yet",
                  style:
                      TextStyle(
                    fontSize: 18,
                  ),
                ),
              )
            : ReorderableListView.builder(
                padding:
                    const EdgeInsets.all(
                  12,
                ),

                itemCount:
                    dayClasses.length,

                onReorder:
                    reorderClasses,

                itemBuilder:
                    (
                  context,
                  index,
                ) {
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
                      leading:
                          CircleAvatar(
                        child: Text(
                          "${index + 1}",
                        ),
                      ),

                      title: Text(
                        entry.subject,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      trailing:
                          Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          IconButton(
                            icon:
                                const Icon(
                              Icons.edit,
                            ),

                            onPressed:
                                saving
                                    ? null
                                    : () {
                                        editClass(
                                          index,
                                        );
                                      },
                          ),

                          IconButton(
                            icon:
                                const Icon(
                              Icons.delete,
                              color:
                                  Colors.red,
                            ),

                            onPressed:
                                saving
                                    ? null
                                    : () {
                                        deleteClass(
                                          index,
                                        );
                                      },
                          ),

                          const Icon(
                            Icons
                                .drag_handle,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

        floatingActionButton:
            FloatingActionButton.extended(
          onPressed:
              saving
                  ? null
                  : addClass,

          icon:
              const Icon(
            Icons.add,
          ),

          label:
              const Text(
            "Add Class",
          ),
        ),
      ),
    );
  }
}