import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_model.dart';

class SubjectService {
  static const String _key = 'backend_simulado_subjects';

  Future<List<SubjectModel>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subjectsJson = prefs.getString(_key);

    if (subjectsJson == null) return [];

    final List<dynamic> decodedList = jsonDecode(subjectsJson);
    return decodedList.map((item) => SubjectModel.fromMap(item)).toList();
  }

  Future<void> postSubject(SubjectModel subject) async {
    final prefs = await SharedPreferences.getInstance();
    final subjects = await getSubjects();
    subjects.add(subject);

    await prefs.setString(
        _key, jsonEncode(subjects.map((e) => e.toMap()).toList()));
  }
}
