import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/subject_model.dart';
import 'task_service.dart';

class SubjectService {
  static const String _key = 'studyflow_subjects';

  Future<List<SubjectModel>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsJson = prefs.getString(_key);

    if (subjectsJson == null || subjectsJson.isEmpty) {
      return [];
    }

    final decodedList = jsonDecode(subjectsJson) as List<dynamic>;
    final subjects = decodedList
        .map((item) => SubjectModel.fromMap(item as Map<String, dynamic>))
        .toList();

    subjects.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return subjects;
  }

  Future<SubjectModel?> getSubjectById(String id) async {
    final subjects = await getSubjects();
    for (final subject in subjects) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }

  Future<void> postSubject(SubjectModel subject) async {
    await _validateSubject(subject);

    final subjects = await getSubjects();
    subjects.add(subject);
    await _saveSubjects(subjects);
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _validateSubject(subject, ignoreId: subject.id);

    final subjects = await getSubjects();
    final index = subjects.indexWhere((element) => element.id == subject.id);

    if (index == -1) {
      throw StateError('Materia nao encontrada.');
    }

    subjects[index] = subject;
    await _saveSubjects(subjects);
  }

  Future<void> deleteSubject(String id) async {
    final subjects = await getSubjects();
    subjects.removeWhere((subject) => subject.id == id);

    await _saveSubjects(subjects);
    await TaskService().deleteTasksBySubject(id);
  }

  Future<void> _saveSubjects(List<SubjectModel> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(subjects.map((subject) => subject.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> _validateSubject(
    SubjectModel subject, {
    String? ignoreId,
  }) async {
    if (subject.name.trim().length < 3) {
      throw ArgumentError('O nome da materia deve ter pelo menos 3 caracteres.');
    }
    if (subject.teacher.trim().length < 3) {
      throw ArgumentError(
        'O nome do professor deve ter pelo menos 3 caracteres.',
      );
    }
    if (subject.workloadHours <= 0) {
      throw ArgumentError('A carga horaria deve ser maior que zero.');
    }

    final subjects = await getSubjects();
    final alreadyExists = subjects.any((item) {
      return item.id != ignoreId &&
          item.name.trim().toLowerCase() == subject.name.trim().toLowerCase();
    });

    if (alreadyExists) {
      throw ArgumentError('Ja existe uma materia com esse nome.');
    }
  }
}
