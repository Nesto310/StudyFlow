import 'package:flutter/foundation.dart';

import '../models/availability_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../services/api_client.dart';

class AppState extends ChangeNotifier {
  AppState({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;
  final List<SubjectModel> _subjects = [];
  final List<TaskModel> _tasks = [];
  final List<TimeSlot> _availabilitySlots = [];
  int _generation = 0;
  bool _disposed = false;
  bool isLoading = false;
  bool hasLoaded = false;
  String? loadError;

  List<SubjectModel> get subjects => List.unmodifiable(_subjects);
  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  List<TimeSlot> get availabilitySlots => List.unmodifiable(_availabilitySlots);

  void clear() {
    _generation++;
    _subjects.clear();
    _tasks.clear();
    _availabilitySlots.clear();
    isLoading = false;
    hasLoaded = false;
    loadError = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> loadData() async {
    if (isLoading || _disposed) return;
    final generation = _generation;
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final result = await Future.wait<Object>([
        _api.getSubjects(),
        _api.getTasks(),
        _api.getAvailability(),
      ]);
      if (!_isCurrent(generation)) return;
      _subjects
        ..clear()
        ..addAll(result[0] as List<SubjectModel>);
      _tasks
        ..clear()
        ..addAll(result[1] as List<TaskModel>);
      _availabilitySlots
        ..clear()
        ..addAll(result[2] as List<TimeSlot>);
      hasLoaded = true;
    } on ApiException catch (error) {
      if (_isCurrent(generation)) loadError = error.message;
    } finally {
      if (_isCurrent(generation)) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<T> _change<T>(
      Future<T> Function() request, void Function(T) apply) async {
    final generation = _generation;
    final result = await request();
    if (!_isCurrent(generation)) throw ApiClient.sessionExpired;
    apply(result);
    notifyListeners();
    return result;
  }

  SubjectModel? findSubjectById(String id) {
    for (final subject in _subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  bool hasTasksForSubject(String subjectId) =>
      _tasks.any((task) => task.subjectId == subjectId);

  Future<SubjectModel> addSubject(
          {required String name, String teacher = ''}) =>
      _change(() => _api.createSubject(name: name, teacher: teacher),
          _subjects.add);

  Future<SubjectModel> updateSubject(String id,
          {String? name, String? teacher}) =>
      _change(() => _api.updateSubject(id, name: name, teacher: teacher),
          (value) {
        final index = _subjects.indexWhere((item) => item.id == id);
        if (index != -1) _subjects[index] = value;
      });

  Future<void> removeSubject(String id) => _change(
        () => _api.deleteSubject(id),
        (_) => _subjects.removeWhere((item) => item.id == id),
      );

  Future<TaskModel> addTask(
          {required String title,
          required String subjectId,
          String description = '',
          required int estimatedMinutes,
          required DateTime dueDate}) =>
      _change(
          () => _api.createTask(
              title: title,
              subjectId: subjectId,
              description: description,
              estimatedMinutes: estimatedMinutes,
              dueDate: dueDate),
          _tasks.add);

  Future<TaskModel> updateTask(String id,
          {String? title,
          String? subjectId,
          String? description,
          int? estimatedMinutes,
          DateTime? dueDate,
          bool? isCompleted}) =>
      _change(
          () => _api.updateTask(id,
              title: title,
              subjectId: subjectId,
              description: description,
              estimatedMinutes: estimatedMinutes,
              dueDate: dueDate,
              isCompleted: isCompleted), (value) {
        final index = _tasks.indexWhere((item) => item.id == id);
        if (index != -1) {
          _tasks[index] = value.copyWith(aiTip: _tasks[index].aiTip);
        }
      });

  Future<void> toggleTaskCompletion(String id) async {
    final task = _tasks.where((item) => item.id == id).firstOrNull;
    if (task == null) return;
    await updateTask(id, isCompleted: !task.isCompleted);
  }

  Future<void> deleteTask(String id) => _change(
        () => _api.deleteTask(id),
        (_) => _tasks.removeWhere((item) => item.id == id),
      );

  void setTaskAiTip(String taskId, String tip) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || _disposed) return;
    _tasks[index] = _tasks[index].copyWith(aiTip: tip);
    notifyListeners();
  }

  Future<TimeSlot> addAvailabilitySlot(
          {required int dayOfWeek,
          required String startTime,
          required String endTime,
          required bool repeatNextWeek}) =>
      _change(
          () => _api.createAvailability(
              dayOfWeek: dayOfWeek,
              startTime: startTime,
              endTime: endTime,
              repeatNextWeek: repeatNextWeek),
          _availabilitySlots.add);

  Future<TimeSlot> updateAvailabilitySlot(String id,
          {int? dayOfWeek,
          String? startTime,
          String? endTime,
          bool? repeatNextWeek}) =>
      _change(
          () => _api.updateAvailability(id,
              dayOfWeek: dayOfWeek,
              startTime: startTime,
              endTime: endTime,
              repeatNextWeek: repeatNextWeek), (value) {
        final index = _availabilitySlots.indexWhere((item) => item.id == id);
        if (index != -1) _availabilitySlots[index] = value;
      });

  Future<void> updateAvailabilityRepeat(String id, bool repeatNextWeek) async {
    await updateAvailabilitySlot(id, repeatNextWeek: repeatNextWeek);
  }

  Future<void> deleteAvailabilitySlot(String id) => _change(
        () => _api.deleteAvailability(id),
        (_) => _availabilitySlots.removeWhere((item) => item.id == id),
      );

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
