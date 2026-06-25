import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../services/subject_service.dart';
import '../services/task_service.dart';

class TaskScreen extends StatefulWidget {
  final String taskId;

  const TaskScreen({super.key, required this.taskId});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TaskService _taskService = TaskService();
  final SubjectService _subjectService = SubjectService();

  Future<_TaskDetailsData?> _loadData() async {
    final task = await _taskService.getTaskById(widget.taskId);
    if (task == null) {
      return null;
    }

    final subject = await _subjectService.getSubjectById(task.subjectId);
    return _TaskDetailsData(task: task, subject: subject);
  }

  Future<void> _toggle(TaskModel task, bool value) async {
    await _taskService.toggleTaskStatus(task.id, value);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _delete(TaskModel task) async {
    await _taskService.deleteTask(task.id);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da tarefa')),
      body: FutureBuilder<_TaskDetailsData?>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Tarefa nao encontrada.'));
          }

          final task = data.task;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(data.subject?.name ?? 'Materia removida'),
              const Divider(height: 32),
              _InfoTile(
                icon: Icons.description_outlined,
                label: 'Descricao',
                value: task.description,
              ),
              _InfoTile(
                icon: Icons.event,
                label: 'Entrega',
                value: _formatDate(task.dueDate),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Concluida'),
                value: task.isCompleted,
                onChanged: (value) => _toggle(task, value),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _delete(task),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir tarefa'),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _TaskDetailsData {
  final TaskModel task;
  final SubjectModel? subject;

  const _TaskDetailsData({
    required this.task,
    required this.subject,
  });
}
