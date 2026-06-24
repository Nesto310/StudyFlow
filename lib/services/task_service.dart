import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskService {
  static const String _storageKey = 'studyflow_tasks';

  // Simula o Método GET: Busca todas as tarefas salvas
  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();[cite: 3, 4]
    final String? tasksJson = prefs.getString(_storageKey);[cite: 3]
    
    if (tasksJson == null) return [];
    
    final List<dynamic> decodedList = jsonDecode(tasksJson);
    return decodedList.map((item) => TaskModel.fromMap(item)).toList();
  }

  // Simula o Método POST: Adiciona/Salva uma nova tarefa
  Future<void> saveTask(TaskModel newTask) async {
    final prefs = await SharedPreferences.getInstance();[cite: 3, 4]
    final List<TaskModel> currentTasks = await getTasks();
    
    // Adiciona a nova tarefa na lista existente
    currentTasks.add(newTask);
    
    // Converte a lista atualizada para JSON e salva
    final String encodedData = jsonEncode(
      currentTasks.map((task) => task.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);[cite: 3]
  }
}