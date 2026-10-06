import 'package:flutter/material.dart';
import '../database/hive_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ==================================================
  // DEFAULT SUBJECTS
  // ==================================================

  final List<String> defaultSubjects = [
    "DSA",
    "COA",
    "Software Engineering",
    "Mathematics III",
    "STLD",
    "Life Skills",
    "DSA Lab",
    "Digital Electronics Lab",
  ];

  late List<String> subjects;

  // ==================================================
  // INIT
  // ==================================================

  @override
  void initState() {
    super.initState();

    subjects = HiveHelper.getSubjects();

    // First installation / no subjects saved
    if (subjects.isEmpty) {
      subjects = List<String>.from(
        defaultSubjects,
      );

      HiveHelper.saveSubjects(
        List<String>.from(subjects),
      );
    }
  }

  // ==================================================
  // ADD SUBJECT
  // ==================================================

  Future<void> addSubject() async {
    String newSubject = "";

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Add Subject",
          ),

          content: TextFormField(
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,

            decoration: const InputDecoration(
              labelText: "Subject name",
              border: OutlineInputBorder(),
            ),

            onChanged: (value) {
              newSubject = value;
            },
          ),

          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                "Cancel",
              ),
            ),

            // ADD
            ElevatedButton(
              onPressed: () {
                final name =
                    newSubject.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(name);
              },
              child: const Text(
                "Add",
              ),
            ),
          ],
        );
      },
    );

    // Cancelled
    if (result == null) {
      return;
    }

    final name = result.trim();

    if (name.isEmpty) {
      return;
    }

    // Duplicate
    if (subjects.contains(name)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Subject already exists",
          ),
        ),
      );

      return;
    }

    // Create new list
    final updatedSubjects =
        List<String>.from(subjects);

    updatedSubjects.add(name);

    // Save
    await HiveHelper.saveSubjects(
      updatedSubjects,
    );

    if (!mounted) return;

    setState(() {
      subjects = updatedSubjects;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '"$name" added',
        ),
      ),
    );
  }

  // ==================================================
  // EDIT / RENAME SUBJECT
  // ==================================================

  Future<void> editSubject(
    int index,
  ) async {
    final oldName = subjects[index];

    String newSubject = oldName;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Edit Subject",
          ),

          content: TextFormField(
            initialValue: oldName,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,

            decoration: const InputDecoration(
              labelText: "Subject name",
              border: OutlineInputBorder(),
            ),

            onChanged: (value) {
              newSubject = value;
            },
          ),

          actions: [
            // ----------------------------------------
            // CANCEL
            // ----------------------------------------

            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                "Cancel",
              ),
            ),

            // ----------------------------------------
            // SAVE
            // ----------------------------------------

            ElevatedButton(
              onPressed: () {
                final name =
                    newSubject.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(name);
              },
              child: const Text(
                "Save",
              ),
            ),
          ],
        );
      },
    );

    // Cancelled
    if (result == null) {
      return;
    }

    final name = result.trim();

    if (name.isEmpty) {
      return;
    }

    // No change
    if (name == oldName) {
      return;
    }

    // Duplicate
    if (subjects.contains(name)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Subject already exists",
          ),
        ),
      );

      return;
    }

    // ==================================================
    // IMPORTANT
    // Rename everywhere:
    //
    // Subject list
    // Timetable
    // Day overrides
    // Attendance
    // Attendance totals
    // ==================================================

    await HiveHelper.renameSubject(
      oldName,
      name,
    );

    if (!mounted) return;

    setState(() {
      subjects[index] = name;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '"$oldName" changed to "$name"',
        ),
      ),
    );
  }

  // ==================================================
  // DELETE SUBJECT
  // ==================================================

  Future<void> deleteSubject(
    int index,
  ) async {
    final subject = subjects[index];

    final confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete Subject?",
          ),

          content: Text(
            'This will permanently delete "$subject" '
            'from your course, timetable and attendance.\n\n'
            'This action cannot be undone.',
          ),

          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                "Cancel",
              ),
            ),

            // DELETE
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // ==================================================
    // IMPORTANT
    // Delete everywhere:
    //
    // Subject list
    // Timetable
    // Day overrides
    // Attendance
    // Attendance totals
    // ==================================================

    await HiveHelper.deleteSubject(
      subject,
    );

    if (!mounted) return;

    setState(() {
      subjects.removeAt(index);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '"$subject" deleted',
        ),
      ),
    );
  }

  // ==================================================
  // RESET ALL DATA
  // ==================================================

  Future<void> resetData() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Reset All Data?",
          ),

          content: const Text(
            "This will permanently delete your "
            "attendance, timetable, subjects, "
            "day changes and other app data.\n\n"
            "This action cannot be undone.",
          ),

          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                "Cancel",
              ),
            ),

            // RESET
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                "Reset",
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // Delete everything
    await HiveHelper.resetAllData();

    // Restore default subjects
    final newSubjects =
        List<String>.from(
      defaultSubjects,
    );

    await HiveHelper.saveSubjects(
      newSubjects,
    );

    if (!mounted) return;

    setState(() {
      subjects = newSubjects;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "All data has been reset",
        ),
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
        title: const Text(
          "Settings",
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),

        children: [
          // ==================================================
          // COURSE
          // ==================================================

          const Text(
            "Course",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Card(
            child: Column(
              children: [
                // ------------------------------------------
                // HEADER
                // ------------------------------------------

                const ListTile(
                  leading: Icon(
                    Icons.menu_book,
                  ),
                  title: Text(
                    "Edit Course",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Add, edit or remove subjects",
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                // ------------------------------------------
                // SUBJECTS
                // ------------------------------------------

                ...List.generate(
                  subjects.length,
                  (index) {
                    return ListTile(
                      title: Text(
                        subjects[index],
                      ),

                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          // EDIT
                          IconButton(
                            icon:
                                const Icon(
                              Icons.edit,
                            ),
                            tooltip:
                                "Edit Subject",
                            onPressed: () {
                              editSubject(
                                index,
                              );
                            },
                          ),

                          // DELETE
                          IconButton(
                            icon:
                                const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            tooltip:
                                "Delete Subject",
                            onPressed: () {
                              deleteSubject(
                                index,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ------------------------------------------
                // ADD SUBJECT
                // ------------------------------------------

                ListTile(
                  leading:
                      const Icon(
                    Icons.add,
                  ),
                  title: const Text(
                    "Add Subject",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  onTap: addSubject,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ==================================================
          // DATA
          // ==================================================

          const Text(
            "Data",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),

              title: const Text(
                "Reset All Data",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              subtitle: const Text(
                "Delete attendance, timetable and course data",
              ),

              trailing:
                  const Icon(
                Icons.chevron_right,
              ),

              onTap: resetData,
            ),
          ),
        ],
      ),
    );
  }
}