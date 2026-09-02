import 'package:flutter/foundation.dart';

import '../models/availability_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';

class AppState extends ChangeNotifier {
  final List<SubjectModel> _subjects = [
    const SubjectModel(
      id: 'subject_algorithms',
      name: 'Algoritmos',
      teacher: 'Prof. Ana',
    ),
    const SubjectModel(
      id: 'subject_database',
      name: 'Banco de Dados',
      teacher: 'Prof. Marcos',
    ),
  ];

  final List<TaskModel> _tasks = [
    TaskModel(
      id: 'task_tree_structures',
      title: 'Estruturas de Dados em Árvore',
      subjectId: 'subject_algorithms',
      description: 'Implementar balanceamento AVL e percurso em ordem.',
      estimatedMinutes: 90,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    TaskModel(
      id: 'task_database_normalization',
      title: 'Normalização de Banco de Dados',
      subjectId: 'subject_database',
      description: '',
      estimatedMinutes: 45,
      dueDate: DateTime.now().add(const Duration(days: 4)),
    ),
  ];

  final List<TimeSlot> _availabilitySlots = [
    TimeSlot(
      id: 'slot_monday_afternoon',
      dayOfWeek: 1,
      startHour: '14:00',
      endHour: '16:00',
      durationMinutes: 120,
      repeatNextWeek: true,
    ),
    TimeSlot(
      id: 'slot_wednesday_night',
      dayOfWeek: 3,
      startHour: '19:00',
      endHour: '21:00',
      durationMinutes: 120,
      repeatNextWeek: true,
    ),
    TimeSlot(
      id: 'slot_friday_morning',
      dayOfWeek: 5,
      startHour: '10:00',
      endHour: '12:00',
      durationMinutes: 120,
      repeatNextWeek: false,
    ),
  ];

  List<SubjectModel> get subjects => List.unmodifiable(_subjects);
  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  List<TimeSlot> get availabilitySlots => List.unmodifiable(_availabilitySlots);

  SubjectModel? findSubjectById(String id) {
    for (final subject in _subjects) {
      if (subject.id == id) {
        return subject;
      }
    }

    return null;
  }

  bool hasTasksForSubject(String subjectId) {
    return _tasks.any((task) => task.subjectId == subjectId);
  }

  SubjectModel addSubject({
    required String name,
    String teacher = '',
  }) {
    final subject = SubjectModel(
      id: 'subject_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      teacher: teacher.trim(),
    );

    _subjects.add(subject);
    notifyListeners();
    return subject;
  }

  bool removeSubject(String id) {
    if (hasTasksForSubject(id)) {
      return false;
    }

    final index = _subjects.indexWhere((subject) => subject.id == id);
    if (index == -1) {
      return false;
    }

    _subjects.removeAt(index);
    notifyListeners();
    return true;
  }

  TaskModel addTask({
    required String title,
    required String subjectId,
    String description = '',
    required int estimatedMinutes,
    required DateTime dueDate,
  }) {
    if (findSubjectById(subjectId) == null) {
      throw ArgumentError.value(subjectId, 'subjectId', 'Disciplina inválida.');
    }

    final task = TaskModel(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      subjectId: subjectId,
      description: description.trim(),
      estimatedMinutes: estimatedMinutes,
      dueDate: dueDate,
    );

    _tasks.add(task);
    notifyListeners();
    return task;
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }

    final task = _tasks[index];
    _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    notifyListeners();
  }

  void setTaskAiTip(String taskId, String tip) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }

    _tasks[index] = _tasks[index].copyWith(aiTip: tip);
    notifyListeners();
  }

  void updateAvailabilityRepeat(String slotId, bool repeatNextWeek) {
    final index = _availabilitySlots.indexWhere((slot) => slot.id == slotId);
    if (index == -1) {
      return;
    }

    _availabilitySlots[index] = _availabilitySlots[index].copyWith(
      repeatNextWeek: repeatNextWeek,
    );
    notifyListeners();
  }
}
