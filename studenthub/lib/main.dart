import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadStudentTasks();
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
// TIMETABLE SCREEN
// -----------------------------------------------------------------------------

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Sample class schedule',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          ScheduleTile(
            time: '09:00 AM',
            subject: 'Mobile Application Development',
            room: 'Room 301',
          ),
          ScheduleTile(
            time: '11:00 AM',
            subject: 'Database Management Systems',
            room: 'Room 204',
          ),
          ScheduleTile(
            time: '02:00 PM',
            subject: 'Data Structures and Algorithms',
            room: 'Lab 2',
          ),
        ],
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

class ScheduleTile extends StatelessWidget {
  const ScheduleTile({
    super.key,
    required this.time,
    required this.subject,
    required this.room,
  });

  final String time;
  final String subject;
  final String room;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.access_time,
          color: Color(0xFF4F46E5),
        ),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(room),
        trailing: Text(time),
      ),
    );
  }
}
