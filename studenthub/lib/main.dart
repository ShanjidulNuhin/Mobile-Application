import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const StudentHubApp());
}

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

// HOME SCREEN

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
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
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
          const Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Assignments',
                  value: '4',
                  icon: Icons.assignment_outlined,
                  color: Color(0xFF4F46E5),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Upcoming',
                  value: '2',
                  icon: Icons.event_outlined,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            "Today's Tasks",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const TaskTile(
            title: 'Complete Flutter UI',
            subtitle: 'Mobile Application Development',
            time: '10:00 AM',
          ),
          const TaskTile(
            title: 'Review database notes',
            subtitle: 'Database Management Systems',
            time: '2:00 PM',
          ),
          const TaskTile(
            title: 'Prepare project proposal',
            subtitle: 'University Project',
            time: '5:00 PM',
          ),
        ],
      ),
    );
  }
}

// TASKS SCREEN


class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _StudentTask {
  _StudentTask({
    required this.title,
    required this.subject,
    this.isCompleted = false,
  });

  final String title;
  final String subject;
  bool isCompleted;

  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'isCompleted': isCompleted,
      };

  factory _StudentTask.fromJson(Map<String, dynamic> json) {
    return _StudentTask(
      title: json['title'] as String,
      subject: json['subject'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class _TasksScreenState extends State<TasksScreen> {
  final List<_StudentTask> _tasks = [
    _StudentTask(
      title: 'Complete Flutter UI',
      subject: 'Mobile Application',
    ),
    _StudentTask(
      title: 'Prepare presentation slides',
      subject: 'University Project',
    ),
    _StudentTask(
      title: 'Review lecture notes',
      subject: 'Computer Science',
    ),
  ];

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();

    final newTask = await showDialog<_StudentTask>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Task name',
                hintText: 'e.g. Finish assignment',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
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

              if (title.isEmpty) return;

              Navigator.pop(
                dialogContext,
                _StudentTask(
                  title: title,
                  subject: subject.isEmpty ? 'General' : subject,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    titleController.dispose();
    subjectController.dispose();

    if (!mounted || newTask == null) return;

    setState(() {
      _tasks.add(newTask);
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        _tasks.where((task) => task.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  size: 32,
                ),
                title: Text(
                  '$completedCount of ${_tasks.length} completed',
                ),
                subtitle: const Text('Keep making progress!'),
              ),
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text('No tasks yet. Tap + to add one!'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];

                      return Card(
                        child: CheckboxListTile(
                          value: task.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              task.isCompleted = value ?? false;
                            });
                          },
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
      ),
    );
  }
}


// TIMETABLE SCREEN

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

// PROFILE SCREEN

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
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
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

// REUSABLE WIDGETS

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

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

class TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const TaskTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0E7FF),
          child: Icon(
            Icons.check_circle_outline,
            color: Color(0xFF4F46E5),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

class ScheduleTile extends StatelessWidget {
  final String time;
  final String subject;
  final String room;

  const ScheduleTile({
    super.key,
    required this.time,
    required this.subject,
    required this.room,
  });

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
