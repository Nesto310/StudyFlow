import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/availability_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    String baseUrl = apiBaseUrl,
    this.timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;
  String? _token;
  int _sessionVersion = 0;
  Future<void> Function()? onUnauthorized;

  void setToken(String? token) {
    _token = token;
    _sessionVersion++;
  }

  void close() {
    onUnauthorized = null;
    setToken(null);
    _client.close();
  }

  static const _invalidResponse = ApiException(
    'O servidor retornou uma resposta inválida. Tente novamente.',
  );
  static const sessionExpired = ApiException(
    'Sua sessão terminou. Entre novamente.',
    statusCode: 401,
  );

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? json,
    Map<String, String>? form,
    bool authenticated = true,
  }) async {
    final version = _sessionVersion;
    final request = http.Request(method, Uri.parse('$_baseUrl/api/v1$path'));
    request.headers['Accept'] = 'application/json';
    if (authenticated) {
      if (_token == null) throw sessionExpired;
      request.headers['Authorization'] = 'Bearer $_token';
    }
    if (form != null) {
      request.bodyFields = form;
    } else if (json != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(json);
    }
    late http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
          'O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar ao servidor.');
    }
    // Ignore responses from a session that has already ended or been replaced.
    if (authenticated && version != _sessionVersion) throw sessionExpired;
    if (authenticated && response.statusCode == 401) {
      await onUnauthorized?.call();
      throw sessionExpired;
    }
    Object? data;
    try {
      if (response.bodyBytes.isNotEmpty) {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } on FormatException {
      if (response.statusCode < 400) throw _invalidResponse;
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response.statusCode, path, data),
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 204) return null;
    return data;
  }

  String _errorMessage(int status, String path, Object? data) {
    if (status == 401) return 'Email ou senha incorretos.';
    if (status == 404) return 'O item não foi encontrado.';
    if (status == 409) {
      final detail = data is Map ? data['detail'] : null;
      if (detail == 'Subject has linked tasks') {
        return 'Não é possível excluir uma disciplina que possui tarefas.';
      }
      if (path == '/auth/register') return 'Este email já está cadastrado.';
      return 'Não foi possível salvar a alteração. Atualize os dados e tente novamente.';
    }
    if (status == 422) {
      final detail = data is Map ? data['detail'] : null;
      if (detail is List && detail.isNotEmpty && detail.first is Map) {
        final location = (detail.first as Map)['loc'];
        final field =
            location is List && location.isNotEmpty ? location.last : null;
        const fields = {
          'email': 'Informe um email válido.',
          'password': 'A senha deve ter entre 8 e 128 caracteres.',
          'name': 'Confira o nome da disciplina.',
          'title': 'Confira o título da tarefa.',
          'estimated_minutes': 'Informe um tempo estimado maior que zero.',
          'due_date': 'Confira a data e o horário de entrega.',
          'day_of_week': 'Selecione um dia da semana válido.',
          'start_time': 'Confira o horário inicial.',
          'end_time': 'O horário final deve ser posterior ao inicial.',
        };
        if (fields.containsKey(field)) return fields[field]!;
      }
      return 'Confira os dados informados e tente novamente.';
    }
    return 'Não foi possível concluir a operação. Tente novamente mais tarde.';
  }

  Future<T> _object<T>(
      Future<Object?> request, T Function(Map<String, dynamic>) mapper) async {
    final data = await request;
    try {
      return mapper(data as Map<String, dynamic>);
    } on FormatException {
      throw _invalidResponse;
    } on TypeError {
      throw _invalidResponse;
    }
  }

  Future<List<T>> _list<T>(
      String path, T Function(Map<String, dynamic>) mapper) async {
    final data = await _request('GET', path);
    try {
      return (data as List)
          .map((item) => mapper(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      throw _invalidResponse;
    } on TypeError {
      throw _invalidResponse;
    }
  }

  Future<UserModel> register(String email, String password) => _object(
        _request('POST', '/auth/register',
            authenticated: false,
            json: {'email': email.trim().toLowerCase(), 'password': password}),
        UserModel.fromJson,
      );

  Future<String> login(String email, String password) => _object(
        _request('POST', '/auth/token', authenticated: false, form: {
          'username': email.trim().toLowerCase(),
          'password': password,
        }),
        (data) {
          final token = data['access_token'] as String;
          if (token.isEmpty || data['token_type'] != 'bearer') {
            throw const FormatException('Invalid token response');
          }
          return token;
        },
      );

  Future<UserModel> getCurrentUser() =>
      _object(_request('GET', '/users/me'), UserModel.fromJson);

  Future<List<SubjectModel>> getSubjects() =>
      _list('/subjects', SubjectModel.fromJson);

  Future<SubjectModel> createSubject(
          {required String name, String teacher = ''}) =>
      _object(
          _request('POST', '/subjects',
              json: {'name': name.trim(), 'teacher': teacher.trim()}),
          SubjectModel.fromJson);

  Future<SubjectModel> updateSubject(String id,
          {String? name, String? teacher}) =>
      _object(
          _request('PATCH', '/subjects/${Uri.encodeComponent(id)}', json: {
            if (name != null) 'name': name.trim(),
            if (teacher != null) 'teacher': teacher.trim(),
          }),
          SubjectModel.fromJson);

  Future<void> deleteSubject(String id) async =>
      _request('DELETE', '/subjects/${Uri.encodeComponent(id)}');

  Future<List<TaskModel>> getTasks() => _list('/tasks', TaskModel.fromJson);

  Future<TaskModel> createTask(
          {required String subjectId,
          required String title,
          String description = '',
          required int estimatedMinutes,
          required DateTime dueDate}) =>
      _object(
          _request('POST', '/tasks', json: {
            'subject_id': subjectId,
            'title': title.trim(),
            'description': description.trim(),
            'estimated_minutes': estimatedMinutes,
            'due_date': dueDate.toUtc().toIso8601String(),
          }),
          TaskModel.fromJson);

  Future<TaskModel> updateTask(String id,
          {String? subjectId,
          String? title,
          String? description,
          int? estimatedMinutes,
          DateTime? dueDate,
          bool? isCompleted}) =>
      _object(
          _request('PATCH', '/tasks/${Uri.encodeComponent(id)}', json: {
            if (subjectId != null) 'subject_id': subjectId,
            if (title != null) 'title': title.trim(),
            if (description != null) 'description': description.trim(),
            if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
            if (dueDate != null) 'due_date': dueDate.toUtc().toIso8601String(),
            if (isCompleted != null) 'is_completed': isCompleted,
          }),
          TaskModel.fromJson);

  Future<void> deleteTask(String id) async =>
      _request('DELETE', '/tasks/${Uri.encodeComponent(id)}');

  Future<List<TimeSlot>> getAvailability() =>
      _list('/availability', TimeSlot.fromJson);

  Future<TimeSlot> createAvailability(
          {required int dayOfWeek,
          required String startTime,
          required String endTime,
          required bool repeatNextWeek}) =>
      _object(
          _request('POST', '/availability', json: {
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
            'repeat_next_week': repeatNextWeek,
          }),
          TimeSlot.fromJson);

  Future<TimeSlot> updateAvailability(String id,
          {int? dayOfWeek,
          String? startTime,
          String? endTime,
          bool? repeatNextWeek}) =>
      _object(
          _request('PATCH', '/availability/${Uri.encodeComponent(id)}', json: {
            if (dayOfWeek != null) 'day_of_week': dayOfWeek,
            if (startTime != null) 'start_time': startTime,
            if (endTime != null) 'end_time': endTime,
            if (repeatNextWeek != null) 'repeat_next_week': repeatNextWeek,
          }),
          TimeSlot.fromJson);

  Future<void> deleteAvailability(String id) async =>
      _request('DELETE', '/availability/${Uri.encodeComponent(id)}');
}
