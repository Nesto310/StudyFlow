import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/task_service.dart';
import '../services/subject_service.dart';
import '../widgets/task_card.dart';
import '../widgets/subject_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyFlow - Controle'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_box), text: 'Tarefas'),
            Tab(icon: Icon(Icons.school), text: 'Matérias'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder(
            future: _taskService.getTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const Center(child: Text('Nenhuma tarefa pendente!'));
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskCard(
                    task: task,
                    onStatusChanged: (value) async {
                      await _taskService.toggleTaskStatus(
                          task.id, value ?? false);
                      setState(() {});
                    },
                  );
                },
              );
            },
          ),
          FutureBuilder(
            future: _subjectService.getSubjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final subjects = snapshot.data ?? [];
              if (subjects.isEmpty) {
                return const Center(child: Text('Nenhuma matéria cadastrada!'));
              }
              return ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, index) =>
                    SubjectCard(subject: subjects[index]),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.pushNamed(context, AppRoutes.addTask)
                .then((_) => setState(() {}));
          } else {
            Navigator.pushNamed(context, AppRoutes.addSubject)
                .then((_) => setState(() {}));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
