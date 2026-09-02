import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyflow/services/api_client.dart';

import '../support/api_fixture.dart';

void main() {
  late ApiFixture f;
  setUp(() {
    f = ApiFixture();
    f.api.setToken('fictitious-token-a');
  });
  tearDown(() => f.dispose());

  test('começa vazio e carrega as três listas da API', () async {
    expect(f.app.subjects, isEmpty);
    expect(f.app.tasks, isEmpty);
    expect(f.app.availabilitySlots, isEmpty);
    final load = f.app.loadData();
    expect(f.app.isLoading, isTrue);
    await load;
    expect(f.app.hasLoaded, isTrue);
    expect(f.app.subjects.single.id, 'subject-a');
    expect(f.app.tasks.single.id, 'task-a');
    expect(f.app.availabilitySlots.single.durationMinutes, 90);
    expect(() => f.app.subjects.clear(), throwsUnsupportedError);
    expect(() => f.app.tasks.clear(), throwsUnsupportedError);
    expect(() => f.app.availabilitySlots.clear(), throwsUnsupportedError);
  });

  test('recarregar substitui dados, sem duplicar', () async {
    await f.app.loadData();
    f.rows['a']!['subjects']!.single['name'] = 'Atualizada';
    await f.app.loadData();
    expect(f.app.subjects.single.name, 'Atualizada');
    expect(f.app.tasks.length, 1);
  });

  test('adiciona disciplina com ID vindo do servidor', () async {
    final subject = await f.app
        .addSubject(name: 'Desenvolvimento Mobile', teacher: 'Prof. Carla');
    expect(subject.id, startsWith('server-'));
    expect(subject.name, 'Desenvolvimento Mobile');
    expect(subject.teacher, 'Prof. Carla');
    expect(f.app.findSubjectById(subject.id), subject);
  });

  test('adiciona tarefa vinculada a uma disciplina remota', () async {
    final subject = await f.app.addSubject(name: 'Engenharia de Software');
    final task = await f.app.addTask(
        title: 'Revisar requisitos',
        subjectId: subject.id,
        estimatedMinutes: 50,
        dueDate: DateTime.utc(2026, 9, 10));
    expect(task.subjectId, subject.id);
    expect(f.app.tasks.last.id, task.id);
    expect(f.app.findSubjectById(task.subjectId), subject);
  });

  test('marca tarefa como concluída somente após PATCH bem-sucedido', () async {
    await f.app.loadData();
    final gate = Completer<http.Response>();
    f.intercept = (request) => request.method == 'PATCH' ? gate.future : null;
    final pending = f.app.toggleTaskCompletion('task-a');
    expect(f.app.tasks.single.isCompleted, isFalse);
    gate.complete(jsonResponse({...taskJson(), 'is_completed': true}));
    await pending;
    expect(f.app.tasks.single.isCompleted, isTrue);
  });

  test('altera recorrência de disponibilidade via PATCH', () async {
    await f.app.loadData();
    await f.app.updateAvailabilityRepeat('slot-a', false);
    expect(f.app.availabilitySlots.single.repeatNextWeek, isFalse);
  });

  test('impede remoção de disciplina com tarefa vinculada (409)', () async {
    await f.app.loadData();
    await expectLater(
        f.app.removeSubject('subject-a'),
        throwsA(isA<ApiException>()
            .having((error) => error.statusCode, 'status', 409)
            .having((error) => error.message, 'message',
                'Não é possível excluir uma disciplina que possui tarefas.')));
    expect(f.app.findSubjectById('subject-a'), isNotNull);
    expect(f.app.tasks.single.id, 'task-a');
  });

  test('remove disciplina sem tarefas depois da confirmação remota', () async {
    final subject = await f.app.addSubject(name: 'Disciplina vazia');
    await f.app.removeSubject(subject.id);
    expect(f.app.subjects, isEmpty);
  });

  test('cria e exclui disponibilidade, calculando duração', () async {
    final slot = await f.app.addAvailabilitySlot(
        dayOfWeek: 4,
        startTime: '18:15',
        endTime: '20:00',
        repeatNextWeek: false);
    expect(slot.id, startsWith('server-'));
    expect(slot.durationMinutes, 105);
    await f.app.deleteAvailabilitySlot(slot.id);
    expect(f.app.availabilitySlots, isEmpty);
  });

  test('exclui tarefa via API e permite excluir disciplina', () async {
    await f.app.loadData();
    await f.app.deleteTask('task-a');
    expect(f.app.tasks, isEmpty);
    await f.app.removeSubject('subject-a');
    expect(f.app.subjects, isEmpty);
  });

  test('falhas de mutações preservam todas as listas anteriores', () async {
    await f.app.loadData();
    f.intercept = (_) => jsonResponse({}, 500);
    final operations = <Future<void> Function()>[
      () async {
        await f.app.addSubject(name: 'Nova');
      },
      () => f.app.removeSubject('subject-a'),
      () => f.app.toggleTaskCompletion('task-a'),
      () => f.app.deleteTask('task-a'),
      () => f.app.updateAvailabilityRepeat('slot-a', false),
      () => f.app.deleteAvailabilitySlot('slot-a'),
      () async {
        await f.app.addAvailabilitySlot(
            dayOfWeek: 1,
            startTime: '09:00',
            endTime: '10:00',
            repeatNextWeek: true);
      },
    ];
    for (final operation in operations) {
      await expectLater(operation(), throwsA(isA<ApiException>()));
      expect(f.app.subjects.single.id, 'subject-a');
      expect(f.app.tasks.single.isCompleted, isFalse);
      expect(f.app.availabilitySlots.single.repeatNextWeek, isTrue);
    }
  });

  test('falha parcial de loading preserva snapshot e permite retry', () async {
    await f.app.loadData();
    f.rows['a']!['subjects']!.clear();
    f.intercept =
        (r) => r.url.path.endsWith('/tasks') ? jsonResponse({}, 500) : null;
    await f.app.loadData();
    expect(f.app.subjects.length, 1);
    expect(f.app.loadError, isNotNull);
    expect(f.app.isLoading, isFalse);
    f.intercept = null;
    await f.app.loadData();
    expect(f.app.subjects, isEmpty);
    expect(f.app.loadError, isNull);
  });

  test('resposta de loading após clear não repopula dados', () async {
    final gate = Completer<http.Response>();
    f.intercept = (r) => r.url.path.endsWith('/subjects') ? gate.future : null;
    final pending = f.app.loadData();
    f.app.clear();
    gate.complete(jsonResponse([subjectJson()]));
    await pending;
    expect(f.app.subjects, isEmpty);
    expect(f.app.tasks, isEmpty);
    expect(f.app.availabilitySlots, isEmpty);
    expect(f.app.hasLoaded, isFalse);
  });

  test('resposta de criação após clear não insere item da sessão anterior',
      () async {
    final gate = Completer<http.Response>();
    f.intercept = (_) => gate.future;
    final pending = f.app.addSubject(name: 'A');
    final assertion = expectLater(pending, throwsA(isA<ApiException>()));
    f.app.clear();
    gate.complete(jsonResponse(subjectJson(), 201));
    await assertion;
    expect(f.app.subjects, isEmpty);
  });

  test('dica local é transitória e não segue no PATCH', () async {
    await f.app.loadData();
    f.app.setTaskAiTip('task-a', 'Dica local');
    await f.app.toggleTaskCompletion('task-a');
    expect(f.app.tasks.single.aiTip, 'Dica local');
    expect(f.requests.last.body, isNot(contains('aiTip')));
    await f.app.loadData();
    expect(f.app.tasks.single.aiTip, isNull);
  });

  test('Planner é calculado pela API e salvo no estado', () async {
    await f.app.loadData();
    await f.app.generateStudyPlan();
    expect(f.app.studyPlan!.blocks.single.taskTitle, 'Revisar árvores AVL');
    expect(f.requests.last.url.path, '/api/v1/planner/plan');
  });
}
