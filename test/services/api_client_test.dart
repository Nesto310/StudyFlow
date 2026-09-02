import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyflow/models/availability_model.dart';
import 'package:studyflow/models/task_model.dart';
import 'package:studyflow/services/api_client.dart';

import '../support/api_fixture.dart';

void main() {
  test('login envia form-urlencoded com username e password sem Bearer',
      () async {
    final api = ApiClient(client: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/auth/token');
      expect(request.headers['content-type'],
          contains('application/x-www-form-urlencoded'));
      expect(request.headers['Authorization'], isNull);
      expect(Uri.splitQueryString(request.body),
          {'username': 'a@example.com', 'password': 'fictitious +& password'});
      return jsonResponse(
          {'access_token': 'fictitious-token', 'token_type': 'bearer'});
    }));
    addTearDown(api.close);
    expect(await api.login(' A@Example.com ', 'fictitious +& password'),
        'fictitious-token');
  });

  test('registro JSON 201 normaliza email e decodifica usuário', () async {
    final api = ApiClient(client: MockClient((request) async {
      expect(request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(request.body),
          {'email': 'a@example.com', 'password': 'fictitious-password'});
      return jsonResponse(userJson(), 201);
    }));
    addTearDown(api.close);
    final user = await api.register(' A@Example.com ', 'fictitious-password');
    expect(user.email, 'a@example.com');
    expect(user.createdAt.isUtc, isTrue);
  });

  test('Bearer centralizado, teacher null e UTF-8 decodificados', () async {
    final api = ApiClient(client: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer fictitious-token');
      return jsonResponse([
        {...subjectJson(), 'name': 'Álgebra'}
      ]);
    }));
    addTearDown(api.close);
    api.setToken('fictitious-token');
    final subjects = await api.getSubjects();
    expect(subjects.single.name, 'Álgebra');
    expect(subjects.single.teacher, '');
  });

  test('204 não exige JSON', () async {
    final api = ApiClient(
        client: MockClient((request) async => http.Response('', 204)));
    addTearDown(api.close);
    api.setToken('fictitious-token');
    await api.deleteSubject('id');
    await api.deleteTask('id');
    await api.deleteAvailability('id');
  });

  for (final entry in {
    401: 'Email ou senha incorretos.',
    404: 'O item não foi encontrado.',
    409: 'Este email já está cadastrado.',
    422: 'Confira os dados informados e tente novamente.',
    500: 'Não foi possível concluir a operação. Tente novamente mais tarde.',
  }.entries) {
    test('erro ${entry.key} não expõe conteúdo arbitrário do servidor',
        () async {
      final api = ApiClient(
          client: MockClient((_) async =>
              http.Response('<html>SQL/private-detail</html>', entry.key)));
      addTearDown(api.close);
      await expectLater(
          api.register('a@example.com', 'fictitious-password'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'status', entry.key)
                .having((e) => e.message, 'message', entry.value),
          ));
    });
  }

  test('422 usa localização do campo sem expor input ou mensagem arbitrária',
      () async {
    final api = ApiClient(
        client: MockClient((_) async => jsonResponse({
              'detail': [
                {
                  'loc': ['body', 'email'],
                  'msg': 'private-detail',
                  'input': 'private-input'
                },
              ]
            }, 422)));
    addTearDown(api.close);
    await expectLater(
        api.register('bad', 'fictitious-password'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Informe um email válido.'),
        ));
  });

  test('401 público não dispara encerramento de sessão', () async {
    final api =
        ApiClient(client: MockClient((_) async => jsonResponse({}, 401)));
    addTearDown(api.close);
    var count = 0;
    api.onUnauthorized = () async {
      count++;
    };
    await expectLater(api.login('a@example.com', 'fictitious-password'),
        throwsA(isA<ApiException>()));
    expect(count, 0);
  });

  test('401 autenticado dispara encerramento da sessão', () async {
    final api =
        ApiClient(client: MockClient((_) async => jsonResponse({}, 401)));
    addTearDown(api.close);
    var count = 0;
    api.setToken('fictitious-token');
    api.onUnauthorized = () async {
      count++;
      api.setToken(null);
    };
    await expectLater(api.getCurrentUser(), throwsA(isA<ApiException>()));
    expect(count, 1);
  });

  test('requisição autenticada sem token não chega à rede', () async {
    final api = ApiClient(
        client: MockClient((_) async => throw StateError('Must not send')));
    addTearDown(api.close);
    await expectLater(api.getSubjects(), throwsA(isA<ApiException>()));
  });

  test('erro de rede amigável', () async {
    final api = ApiClient(
        client:
            MockClient((_) async => throw http.ClientException('private-url')));
    addTearDown(api.close);
    await expectLater(
        api.login('a@example.com', 'fictitious-password'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message',
              'Não foi possível conectar ao servidor.'),
        ));
  });

  test('timeout cobre espera da resposta', () async {
    final gate = Completer<http.Response>();
    final api = ApiClient(
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) => gate.future));
    addTearDown(api.close);
    await expectLater(
        api.login('a@example.com', 'fictitious-password'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', contains('demorou')),
        ));
    gate.complete(jsonResponse({}));
  });

  for (final body in ['<html>private</html>', '{}', '[{}]']) {
    test('resposta malformada é sanitizada: $body', () async {
      final api =
          ApiClient(client: MockClient((_) async => http.Response(body, 200)));
      addTearDown(api.close);
      api.setToken('fictitious-token');
      await expectLater(api.getTasks(), throwsA(isA<ApiException>()));
    });
  }

  test('task UTC e payload sem aiTip, IDs ou user_id locais', () async {
    final fixture = ApiFixture(seeded: false);
    addTearDown(fixture.dispose);
    fixture.api.setToken('fictitious-token-a');
    final date = DateTime.parse('2026-09-10T15:30:00-03:00');
    final task = await fixture.api.createTask(
        subjectId: 'subject-a',
        title: '  Revisão  ',
        estimatedMinutes: 30,
        dueDate: date);
    final payload = jsonDecode(fixture.requests.last.body) as Map;
    expect(payload['due_date'], '2026-09-10T18:30:00.000Z');
    expect(payload.keys, isNot(contains('aiTip')));
    expect(payload.keys, isNot(contains('id')));
    expect(payload.keys, isNot(contains('user_id')));
    expect(task.id, startsWith('server-'));
    expect(task.dueDate, date);
    expect(TaskModel.fromJson(taskJson()).aiTip, isNull);
  });

  test('métodos update enviam somente campos fornecidos', () async {
    final fixture = ApiFixture();
    addTearDown(fixture.dispose);
    fixture.api.setToken('fictitious-token-a');
    await fixture.api.updateSubject('subject-a', teacher: ' Profa. Ana ');
    expect(jsonDecode(fixture.requests.last.body), {'teacher': 'Profa. Ana'});
    await fixture.api.updateTask('task-a', isCompleted: true);
    expect(jsonDecode(fixture.requests.last.body), {'is_completed': true});
    await fixture.api.updateAvailability('slot-a', repeatNextWeek: false);
    expect(jsonDecode(fixture.requests.last.body), {'repeat_next_week': false});
  });

  for (final time in ['09:15', '09:15:00', '09:15:30.123456']) {
    test('converte horário FastAPI $time', () {
      expect(TimeSlot.timeToMinutes(time), 555);
      final slot = TimeSlot.fromJson({...slotJson(), 'start_time': time});
      expect(slot.startHour, '09:15');
      expect(slot.durationMinutes, 90);
    });
  }
  for (final time in ['24:00', '09:60', '09:15:60', '09:15Z', 'abc']) {
    test('rejeita horário inválido $time', () {
      expect(() => TimeSlot.timeToMinutes(time), throwsFormatException);
    });
  }
}
