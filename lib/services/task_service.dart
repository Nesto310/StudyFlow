import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskService {
  static const String _key = 'backend_simulado_tasks';

  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_key);

    if (tasksJson == null) return [];

    final List<dynamic> decodedList = jsonDecode(tasksJson);
    return decodedList.map((item) => TaskModel.fromMap(item)).toList();
  }

  Future<void> postTask(TaskModel task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getTasks();
    tasks.add(task);

    await prefs.setString(
        _key, jsonEncode(tasks.map((e) => e.toMap()).toList()));
  }

  Future<void> toggleTaskStatus(String id, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getTasks();
    final index = tasks.indexWhere((element) => element.id == id);

    if (index != -1) {
      tasks[index] = TaskModel(
        id: tasks[index].id,
        title: tasks[index].title,
        description: tasks[index].description,
        isCompleted: status,
      );
      await prefs.setString(
          _key, jsonEncode(tasks.map((e) => e.toMap()).toList()));
    }
  }
}
