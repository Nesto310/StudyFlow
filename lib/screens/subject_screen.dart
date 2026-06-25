import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../services/subject_service.dart';
import '../services/task_service.dart';

class SubjectScreen extends StatefulWidget {
  final String subjectId;

  const SubjectScreen({super.key, required this.subjectId});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final SubjectService _subjectService = SubjectService();
  final TaskService _taskService = TaskService();

  Future<_SubjectDetailsData?> _loadData() async {
    final subject = await _subjectService.getSubjectById(widget.subjectId);
    if (subject == null) {
      return null;
    }

    final tasks = await _taskService.getTasksBySubject(subject.id);
    return _SubjectDetailsData(subject: subject, tasks: tasks);
  }

  Future<void> _delete(SubjectModel subject) async {
    await _subjectService.deleteSubject(subject.id);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da materia')),
      body: FutureBuilder<_SubjectDetailsData?>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Materia nao encontrada.'));
          }

          final subject = data.subject;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                subject.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Professor: ${subject.teacher}'),
              Text('Carga horaria: ${subject.workloadHours}h'),
              const Divider(height: 32),
              Text(
                'Tarefas vinculadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (data.tasks.isEmpty)
                const Text('Nenhuma tarefa cadastrada para esta materia.')
              else
                ...data.tasks.map(
                  (task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(task.title),
                    subtitle: Text(_formatDate(task.dueDate)),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _delete(subject),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir materia e tarefas'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _SubjectDetailsData {
  final SubjectModel subject;
  final List<TaskModel> tasks;

  const _SubjectDetailsData({
    required this.subject,
    required this.tasks,
  });
}
