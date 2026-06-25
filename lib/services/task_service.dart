import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';

class TaskService {
  static const String _key = 'studyflow_tasks';

  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_key);

    if (tasksJson == null || tasksJson.isEmpty) {
      return [];
    }

    final decodedList = jsonDecode(tasksJson) as List<dynamic>;
    final tasks = decodedList
        .map((item) => TaskModel.fromMap(item as Map<String, dynamic>))
        .toList();

    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  Future<TaskModel?> getTaskById(String id) async {
    final tasks = await getTasks();
    for (final task in tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  Future<List<TaskModel>> getTasksBySubject(String subjectId) async {
    final tasks = await getTasks();
    return tasks.where((task) => task.subjectId == subjectId).toList();
  }

  Future<void> postTask(TaskModel task) async {
    _validateTask(task);

    final tasks = await getTasks();
    tasks.add(task);
    await _saveTasks(tasks);
  }

  Future<void> updateTask(TaskModel task) async {
    _validateTask(task);

    final tasks = await getTasks();
    final index = tasks.indexWhere((element) => element.id == task.id);

    if (index == -1) {
      throw StateError('Tarefa nao encontrada.');
    }

    tasks[index] = task;
    await _saveTasks(tasks);
  }

  Future<void> deleteTask(String id) async {
    final tasks = await getTasks();
    tasks.removeWhere((task) => task.id == id);
    await _saveTasks(tasks);
  }

  Future<void> deleteTasksBySubject(String subjectId) async {
    final tasks = await getTasks();
    tasks.removeWhere((task) => task.subjectId == subjectId);
    await _saveTasks(tasks);
  }

  Future<void> toggleTaskStatus(String id, bool status) async {
    final task = await getTaskById(id);
    if (task == null) {
      return;
    }

    await updateTask(task.copyWith(isCompleted: status));
  }

  Future<void> _saveTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((task) => task.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  void _validateTask(TaskModel task) {
    if (task.title.trim().length < 3) {
      throw ArgumentError('O titulo deve ter pelo menos 3 caracteres.');
    }
    if (task.description.trim().length < 5) {
      throw ArgumentError('A descricao deve ter pelo menos 5 caracteres.');
    }
    if (task.subjectId.trim().isEmpty) {
      throw ArgumentError('Selecione uma materia para a tarefa.');
    }
  }
}
