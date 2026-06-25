import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../routes/app_routes.dart';
import '../services/subject_service.dart';
import '../services/task_service.dart';
import '../widgets/subject_card.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  final SubjectService _subjectService = SubjectService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_HomeData> _loadData() async {
    final tasks = await _taskService.getTasks();
    final subjects = await _subjectService.getSubjects();
    return _HomeData(tasks: tasks, subjects: subjects);
  }

  void _reload() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteTask(String id) async {
    await _taskService.deleteTask(id);
    _reload();
  }

  Future<void> _deleteSubject(String id) async {
    await _subjectService.deleteSubject(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyFlow - Controle academico'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_box), text: 'Tarefas'),
            Tab(icon: Icon(Icons.school), text: 'Materias'),
          ],
        ),
      ),
      body: FutureBuilder<_HomeData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const _HomeData.empty();

          return TabBarView(
            controller: _tabController,
            children: [
              _TasksTab(
                tasks: data.tasks,
                subjects: data.subjects,
                onToggle: (task, value) async {
                  await _taskService.toggleTaskStatus(task.id, value ?? false);
                  _reload();
                },
                onOpen: (task) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.taskDetails,
                    arguments: task.id,
                  ).then((_) => _reload());
                },
                onDelete: _deleteTask,
              ),
              _SubjectsTab(
                subjects: data.subjects,
                onOpen: (subject) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.subjectDetails,
                    arguments: subject.id,
                  ).then((_) => _reload());
                },
                onDelete: _deleteSubject,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final route = _tabController.index == 0
              ? AppRoutes.addTask
              : AppRoutes.addSubject;
          Navigator.pushNamed(context, route).then((_) => _reload());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<SubjectModel> subjects;
  final void Function(TaskModel task, bool? value) onToggle;
  final void Function(TaskModel task) onOpen;
  final void Function(String id) onDelete;

  const _TasksTab({
    required this.tasks,
    required this.subjects,
    required this.onToggle,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const _EmptyState(
        icon: Icons.assignment_outlined,
        message: 'Nenhuma tarefa cadastrada.',
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final subjectName = _findSubjectName(subjects, task.subjectId);

        return TaskCard(
          task: task,
          subjectName: subjectName ?? 'Materia removida',
          onStatusChanged: (value) => onToggle(task, value),
          onTap: () => onOpen(task),
          onDelete: () => onDelete(task.id),
        );
      },
    );
  }

  String? _findSubjectName(List<SubjectModel> subjects, String subjectId) {
    for (final subject in subjects) {
      if (subject.id == subjectId) {
        return subject.name;
      }
    }
    return null;
  }
}

class _SubjectsTab extends StatelessWidget {
  final List<SubjectModel> subjects;
  final void Function(SubjectModel subject) onOpen;
  final void Function(String id) onDelete;

  const _SubjectsTab({
    required this.subjects,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const _EmptyState(
        icon: Icons.school_outlined,
        message: 'Nenhuma materia cadastrada.',
      );
    }

    return ListView.builder(
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return SubjectCard(
          subject: subject,
          onTap: () => onOpen(subject),
          onDelete: () => onDelete(subject.id),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}

class _HomeData {
  final List<TaskModel> tasks;
  final List<SubjectModel> subjects;

  const _HomeData({
    required this.tasks,
    required this.subjects,
  });

  const _HomeData.empty()
      : tasks = const [],
        subjects = const [];
}
