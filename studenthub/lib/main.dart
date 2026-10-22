import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadStudentTasks();
  await loadStudentTimetable();
  runApp(const StudentHubApp());
}

// -----------------------------------------------------------------------------
// APP
// -----------------------------------------------------------------------------

class StudentHubApp extends StatelessWidget {
  const StudentHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudentHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TasksScreen(),
    TimetableScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TASK MODEL AND SHARED LOCAL STORAGE
// -----------------------------------------------------------------------------

class StudentTask {
  StudentTask({
    required this.title,
    required this.subject,
    this.isCompleted = false,
  });

  final String title;
  final String subject;
  bool isCompleted;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subject': subject,
      'isCompleted': isCompleted,
    };
  }

  factory StudentTask.fromJson(Map<String, dynamic> json) {
    return StudentTask(
      title: json['title'] as String? ?? 'Untitled task',
      subject: json['subject'] as String? ?? 'General',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

const String _tasksStorageKey = 'studenthub_tasks';

final ValueNotifier<List<StudentTask>> studentTasks =
    ValueNotifier<List<StudentTask>>([
  StudentTask(
    title: 'Complete Flutter UI',
    subject: 'Mobile Application',
  ),
  StudentTask(
    title: 'Prepare presentation slides',
    subject: 'University Project',
  ),
  StudentTask(
    title: 'Review lecture notes',
    subject: 'Computer Science',
  ),
]);

Future<void> loadStudentTasks() async {
  final prefs = await SharedPreferences.getInstance();
  final savedTasks = prefs.getStringList(_tasksStorageKey);

  if (savedTasks == null) {
    await saveStudentTasks();
    return;
  }

  try {
    final loadedTasks = savedTasks.map((item) {
      return StudentTask.fromJson(
        jsonDecode(item) as Map<String, dynamic>,
      );
    }).toList();

    studentTasks.value = loadedTasks;
  } catch (error) {
    debugPrint('Could not load saved tasks: $error');
  }
}

Future<void> saveStudentTasks() async {
  final prefs = await SharedPreferences.getInstance();
  final encodedTasks = studentTasks.value
      .map((task) => jsonEncode(task.toJson()))
      .toList();

  await prefs.setStringList(_tasksStorageKey, encodedTasks);
}

// -----------------------------------------------------------------------------
// HOME / DASHBOARD
// -----------------------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StudentHub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications will be available later.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<StudentTask>>(
        valueListenable: studentTasks,
        builder: (context, tasks, _) {
          final completedCount =
              tasks.where((task) => task.isCompleted).length;
          final pendingCount = tasks.length - completedCount;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Hello, Student! 👋',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to make today productive?',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Total Tasks',
                      value: '${tasks.length}',
                      icon: Icons.assignment_outlined,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Remaining',
                      value: '$pendingCount',
                      icon: Icons.event_outlined,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF059669),
                  ),
                  title: Text('$completedCount tasks completed'),
                  subtitle: const Text('Every step forward counts.'),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Today's Tasks",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No tasks yet. Visit the Tasks tab to add one!',
                  ),
                )
              else
                ...tasks.take(3).map((task) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: task.isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(task.subject),
                      trailing: Text(
                        task.isCompleted ? 'Done' : 'Pending',
                        style: TextStyle(
                          color: task.isCompleted
                              ? Colors.green
                              : Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
              if (tasks.length > 3)
                Text(
                  'And ${tasks.length - 3} more task(s).',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TASKS SCREEN
// -----------------------------------------------------------------------------

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Future<void> _addTask() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();

    try {
      final newTask = await showDialog<StudentTask>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add New Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task name',
                    hintText: 'e.g. Finish assignment',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Subject or category',
                    hintText: 'e.g. Programming',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final subject = subjectController.text.trim();

                  if (title.isEmpty) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    StudentTask(
                      title: title,
                      subject: subject.isEmpty ? 'General' : subject,
                    ),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );

      if (!mounted || newTask == null) {
        return;
      }

      studentTasks.value = [...studentTasks.value, newTask];
      await saveStudentTasks();
    } finally {
      titleController.dispose();
      subjectController.dispose();
    }
  }

  Future<void> _toggleTask(StudentTask task, bool? value) async {
    task.isCompleted = value ?? false;
    studentTasks.value = [...studentTasks.value];
    await saveStudentTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: ValueListenableBuilder<List<StudentTask>>(
        valueListenable: studentTasks,
        builder: (context, tasks, _) {
          final completedCount =
              tasks.where((task) => task.isCompleted).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      size: 32,
                    ),
                    title: Text('$completedCount of ${tasks.length} completed'),
                    subtitle: const Text('Keep making progress!'),
                  ),
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Text('No tasks yet. Tap + to add one!'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];

                          return Card(
                            child: CheckboxListTile(
                              value: task.isCompleted,
                              onChanged: (value) => _toggleTask(task, value),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              subtitle: Text(task.subject),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TIMETABLE MODEL AND LOCAL STORAGE
// -----------------------------------------------------------------------------

const String _timetableStorageKey = 'studenthub_timetable';

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class StudentClassSchedule {
  StudentClassSchedule({
    required this.course,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    required this.room,
  });

  final String course;
  final String day;
  final int startMinutes;
  final int endMinutes;
  final String room;

  Map<String, dynamic> toJson() => {
        'course': course,
        'day': day,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'room': room,
      };

  factory StudentClassSchedule.fromJson(Map<String, dynamic> json) {
    return StudentClassSchedule(
      course: json['course'] as String? ?? 'Untitled class',
      day: json['day'] as String? ?? 'Monday',
      startMinutes: json['startMinutes'] as int? ?? 540,
      endMinutes: json['endMinutes'] as int? ?? 600,
      room: json['room'] as String? ?? 'Room not set',
    );
  }
}

final ValueNotifier<List<StudentClassSchedule>> studentTimetable =
    ValueNotifier<List<StudentClassSchedule>>([]);

Future<void> loadStudentTimetable() async {
  final prefs = await SharedPreferences.getInstance();
  final savedClasses = prefs.getStringList(_timetableStorageKey);
  if (savedClasses == null) return;

  try {
    studentTimetable.value = savedClasses.map((item) {
      return StudentClassSchedule.fromJson(
        jsonDecode(item) as Map<String, dynamic>,
      );
    }).toList();
  } catch (error) {
    debugPrint('Could not load saved timetable: $error');
  }
}

Future<void> saveStudentTimetable() async {
  final prefs = await SharedPreferences.getInstance();
  final encodedClasses = studentTimetable.value
      .map((classItem) => jsonEncode(classItem.toJson()))
      .toList();
  await prefs.setStringList(_timetableStorageKey, encodedClasses);
}

// -----------------------------------------------------------------------------
// TIMETABLE SCREEN
// -----------------------------------------------------------------------------

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String _selectedDay = 'Monday';

  String _formatTime(int minutes) {
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _showClassDialog({StudentClassSchedule? existing}) async {
    final courseController = TextEditingController(text: existing?.course ?? '');
    final roomController = TextEditingController(text: existing?.room ?? '');
    String selectedDay = existing?.day ?? _selectedDay;
    int startMinutes = existing?.startMinutes ?? 9 * 60;
    int endMinutes = existing?.endMinutes ?? 10 * 60;

    try {
      final result = await showDialog<StudentClassSchedule>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> chooseTime({required bool isStart}) async {
                final currentMinutes = isStart ? startMinutes : endMinutes;
                final picked = await showTimePicker(
                  context: dialogContext,
                  initialTime: TimeOfDay(
                    hour: currentMinutes ~/ 60,
                    minute: currentMinutes % 60,
                  ),
                );
                if (picked != null) {
                  setDialogState(() {
                    final minutes = picked.hour * 60 + picked.minute;
                    if (isStart) {
                      startMinutes = minutes;
                    } else {
                      endMinutes = minutes;
                    }
                  });
                }
              }

              return AlertDialog(
                title: Text(existing == null ? 'Add class' : 'Edit class'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: courseController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Course name',
                          hintText: 'e.g. Database Management Systems',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDay,
                        decoration: const InputDecoration(labelText: 'Day'),
                        items: _weekdays
                            .map((day) => DropdownMenuItem(
                                  value: day,
                                  child: Text(day),
                                ))
                            .toList(),
                        onChanged: (day) {
                          if (day != null) {
                            setDialogState(() => selectedDay = day);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => chooseTime(isStart: true),
                              icon: const Icon(Icons.login),
                              label: Text('Start\n${_formatTime(startMinutes)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => chooseTime(isStart: false),
                              icon: const Icon(Icons.logout),
                              label: Text('End\n${_formatTime(endMinutes)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: roomController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Room / location',
                          hintText: 'e.g. Room 301',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final course = courseController.text.trim();
                      final room = roomController.text.trim();
                      if (course.isEmpty || endMinutes <= startMinutes) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter a course name and an end time after the start time.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(
                        dialogContext,
                        StudentClassSchedule(
                          course: course,
                          day: selectedDay,
                          startMinutes: startMinutes,
                          endMinutes: endMinutes,
                          room: room.isEmpty ? 'Room not set' : room,
                        ),
                      );
                    },
                    child: Text(existing == null ? 'Add class' : 'Save changes'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || result == null) return;

      if (existing == null) {
        studentTimetable.value = [...studentTimetable.value, result];
      } else {
        final index = studentTimetable.value.indexOf(existing);
        if (index != -1) {
          final updated = [...studentTimetable.value];
          updated[index] = result;
          studentTimetable.value = updated;
        }
      }

      setState(() => _selectedDay = result.day);
      await saveStudentTimetable();
    } finally {
      courseController.dispose();
      roomController.dispose();
    }
  }

  Future<void> _deleteClass(StudentClassSchedule classItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('Remove "${classItem.course}" from your timetable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    studentTimetable.value = studentTimetable.value
        .where((item) => !identical(item, classItem))
        .toList();
    await saveStudentTimetable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add class'),
      ),
      body: ValueListenableBuilder<List<StudentClassSchedule>>(
        valueListenable: studentTimetable,
        builder: (context, classes, _) {
          final dayClasses = classes
              .where((classItem) => classItem.day == _selectedDay)
              .toList()
            ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              const Text(
                'Your weekly schedule',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your classes and keep your schedule in one place.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _weekdays.map((day) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(day.substring(0, 3)),
                        selected: _selectedDay == day,
                        onSelected: (_) => setState(() => _selectedDay = day),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (dayClasses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 44,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No classes on $_selectedDay',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap “Add class” to build your timetable.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...dayClasses.map((classItem) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 4,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(
                        classItem.course,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${_formatTime(classItem.startMinutes)} – '
                          '${_formatTime(classItem.endMinutes)}\n'
                          '${classItem.room}',
                        ),
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Class options',
                        onSelected: (choice) {
                          if (choice == 'edit') {
                            _showClassDialog(existing: classItem);
                          } else if (choice == 'delete') {
                            _deleteClass(classItem);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              if (classes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${classes.length} class${classes.length == 1 ? '' : 'es'} '
                  'saved across your week',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROFILE SCREEN
// -----------------------------------------------------------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Student Name',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'University Student',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.school_outlined),
                  title: Text('Education'),
                  subtitle: Text('Add your university details later'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  subtitle: Text('More settings coming soon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE WIDGETS
// -----------------------------------------------------------------------------

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
