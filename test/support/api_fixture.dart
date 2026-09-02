import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyflow/services/api_client.dart';
import 'package:studyflow/services/token_storage.dart';
import 'package:studyflow/state/app_state.dart';
import 'package:studyflow/state/auth_state.dart';

http.Response jsonResponse(Object? data, [int status = 200]) => http.Response(
      data == null ? '' : jsonEncode(data),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> userJson([String owner = 'a']) => {
      'id': 'user-$owner',
      'email': '$owner@example.com',
      'created_at': '2026-09-01T12:00:00Z',
      'updated_at': '2026-09-01T12:00:00Z',
    };

Map<String, dynamic> subjectJson([String owner = 'a']) => {
      'id': 'subject-$owner',
      'name': 'Disciplina $owner',
      'teacher': null,
    };

Map<String, dynamic> taskJson([String owner = 'a']) => {
      'id': 'task-$owner',
      'subject_id': 'subject-$owner',
      'title': 'Tarefa $owner',
      'description': '',
      'estimated_minutes': 60,
      'due_date': '2026-09-10T18:30:00Z',
      'is_completed': false,
    };

Map<String, dynamic> slotJson([String owner = 'a']) => {
      'id': 'slot-$owner',
      'day_of_week': 1,
      'start_time': '09:15:00',
      'end_time': '10:45:00',
      'repeat_next_week': true,
    };

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);
  String? token;
  int saves = 0;
  int deletes = 0;
  bool failRead = false;
  bool failSave = false;
  bool failDelete = false;
  Completer<void>? saveGate;

  @override
  Future<String?> readToken() async {
    if (failRead) throw StateError('Storage unavailable');
    return token;
  }

  @override
  Future<void> saveToken(String value) async {
    saves++;
    await saveGate?.future;
    if (failSave) throw StateError('Storage unavailable');
    token = value;
  }

  @override
  Future<void> deleteToken() async {
    deletes++;
    if (failDelete) throw StateError('Storage unavailable');
    token = null;
  }
}

class ApiFixture {
  ApiFixture({String? savedToken, bool seeded = true, bool demoMode = false}) {
    for (final owner in ['a', 'b']) {
      rows[owner] = {
        'subjects': seeded ? [subjectJson(owner)] : [],
        'tasks': seeded ? [taskJson(owner)] : [],
        'availability': seeded ? [slotJson(owner)] : [],
      };
    }
    storage = MemoryTokenStorage(savedToken);
    api = ApiClient(
        client: MockClient(_handle), baseUrl: 'http://localhost:8000/');
    app = AppState(apiClient: api);
    auth = AuthState(
        apiClient: api,
        tokenStorage: storage,
        appState: app,
        demoMode: demoMode);
  }

  late final ApiClient api;
  late final AppState app;
  late final AuthState auth;
  late final MemoryTokenStorage storage;
  final requests = <http.Request>[];
  final rows = <String, Map<String, List<Map<String, dynamic>>>>{};
  FutureOr<http.Response?> Function(http.Request)? intercept;
  int _counter = 0;

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final intercepted = await intercept?.call(request);
    if (intercepted != null) return intercepted;
    final path = request.url.path;
    if (path.endsWith('/dev/demo-session')) {
      return jsonResponse(
          {'access_token': 'fictitious-demo-token-a', 'token_type': 'bearer'});
    }
    if (path.endsWith('/planner/plan')) return jsonResponse(planJson());
    if (path.endsWith('/auth/token')) {
      final form = Uri.splitQueryString(request.body);
      final owner = form['username']!.startsWith('b') ? 'b' : 'a';
      return jsonResponse(
          {'access_token': 'fictitious-token-$owner', 'token_type': 'bearer'});
    }
    if (path.endsWith('/auth/register')) return jsonResponse(userJson(), 201);
    final owner =
        request.headers['Authorization']?.endsWith('-b') == true ? 'b' : 'a';
    if (path.endsWith('/users/me')) return jsonResponse(userJson(owner));
    final parts = request.url.pathSegments.skip(2).toList();
    final collection = rows[owner]![parts.first]!;
    if (request.method == 'GET') return jsonResponse(collection);
    if (request.method == 'POST') {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final row = <String, dynamic>{
        if (parts.first == 'tasks') ...taskJson(owner),
        ...payload,
        'id': 'server-${parts.first}-${++_counter}',
      };
      collection.add(row);
      return jsonResponse(row, 201);
    }
    final row = collection.where((row) => row['id'] == parts.last).firstOrNull;
    if (row == null) return jsonResponse({'detail': 'Not found'}, 404);
    if (request.method == 'PATCH') {
      row.addAll(jsonDecode(request.body) as Map<String, dynamic>);
      return jsonResponse(row);
    }
    if (parts.first == 'subjects' &&
        rows[owner]!['tasks']!.any((task) => task['subject_id'] == row['id'])) {
      return jsonResponse({'detail': 'Subject has linked tasks'}, 409);
    }
    collection.remove(row);
    return jsonResponse(null, 204);
  }

  Future<void> settle() async {
    while (app.isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void dispose() {
    auth.dispose();
    app.dispose();
    api.close();
  }
}

Map<String, dynamic> planJson() => {
      'generated_at': '2026-09-07T18:00:00Z',
      'horizon_start': '2026-09-07T18:00:00Z',
      'horizon_end': '2026-09-21T18:00:00Z',
      'timezone_offset_minutes': -180,
      'blocks': [
        {
          'task_id': 'task-a',
          'subject_id': 'subject-a',
          'subject_name': 'Algoritmos',
          'task_title': 'Revisar árvores AVL',
          'start_at': '2026-09-07T22:00:00Z',
          'end_at': '2026-09-07T23:00:00Z',
          'planned_minutes': 60,
          'due_date': '2026-09-10T18:30:00Z',
        }
      ],
      'tasks': [
        {
          'task_id': 'task-a',
          'subject_id': 'subject-a',
          'subject_name': 'Algoritmos',
          'task_title': 'Revisar árvores AVL',
          'due_date': '2026-09-10T18:30:00Z',
          'estimated_minutes': 60,
          'planned_minutes': 60,
          'unscheduled_minutes': 0,
          'risk': 'on_track',
        }
      ],
      'summary': {
        'total_pending_tasks': 1,
        'total_planned_minutes': 60,
        'total_unscheduled_minutes': 0,
        'total_available_minutes': 240,
        'on_track_tasks': 1,
        'at_risk_tasks': 0,
        'overdue_tasks': 0,
      },
    };
