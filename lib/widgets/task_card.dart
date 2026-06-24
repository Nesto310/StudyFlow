import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<bool?> onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(task.description),
        trailing: Checkbox(
          value: task.isCompleted,
          onChanged: onStatusChanged,
        ),
      ),
    );
  }
}
