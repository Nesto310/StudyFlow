import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyflow/models/study_plan_model.dart';
import 'package:studyflow/services/api_client.dart';

import 'support/api_fixture.dart';

void main() {
  late ApiFixture f;
  setUp(() {
    f = ApiFixture();
    f.api.setToken('fictitious-token-a');
  });
  tearDown(() => f.dispose());

  test('models decodificam todos os campos, datas UTC e listas imutáveis', () {
    final plan = StudyPlan.fromJson(planJson());
    expect(plan.generatedAt, DateTime.utc(2026, 9, 7, 18));
    expect(plan.horizonEnd.difference(plan.horizonStart).inDays, 14);
    expect(plan.timezoneOffsetMinutes, -180);
    final block = plan.blocks.single;
    expect(block.taskId, 'task-a');
    expect(block.subjectId, 'subject-a');
    expect(block.subjectName, 'Algoritmos');
    expect(block.taskTitle, 'Revisar árvores AVL');
    expect(block.startAt.isUtc, isTrue);
    expect(
        block.endAt.difference(block.startAt).inMinutes, block.plannedMinutes);
    expect(block.dueDate, DateTime.utc(2026, 9, 10, 18, 30));
    final task = plan.tasks.single;
    expect(task.taskId, block.taskId);
    expect(task.subjectId, block.subjectId);
    expect(task.taskTitle, block.taskTitle);
    expect(task.subjectName, block.subjectName);
    expect(task.dueDate, block.dueDate);
    expect(task.estimatedMinutes, 60);
    expect(task.plannedMinutes, 60);
    expect(task.unscheduledMinutes, 0);
    expect(task.risk, StudyPlanRisk.onTrack);
    expect(plan.summary.totalPendingTasks, 1);
    expect(plan.summary.totalPlannedMinutes, 60);
    expect(plan.summary.totalUnscheduledMinutes, 0);
    expect(plan.summary.totalAvailableMinutes, 240);
    expect(plan.summary.onTrackTasks, 1);
    expect(plan.summary.atRiskTasks, 0);
    expect(plan.summary.overdueTasks, 0);
    expect(() => plan.tasks.clear(), throwsUnsupportedError);
    expect(() => plan.blocks.clear(), throwsUnsupportedError);
  });

  for (final entry in {
    'at_risk': StudyPlanRisk.atRisk,
    'overdue': StudyPlanRisk.overdue
  }.entries) {
    test('parse do risco ${entry.key}', () {
      final data = planJson();
      (data['tasks'] as List).single['risk'] = entry.key;
      expect(StudyPlan.fromJson(data).tasks.single.risk, entry.value);
    });
  }

  test('POST Planner envia somente opções, Bearer e offset local atual',
      () async {
    final result = await f.api.generateStudyPlan();
    final request = f.requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/planner/plan');
    expect(request.headers['Authorization'], 'Bearer fictitious-token-a');
    expect(jsonDecode(request.body), {
      'horizon_days': 14,
      'timezone_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
    });
    expect(result.blocks.single.plannedMinutes, 60);
  });

  test('Planner aceita opções determinísticas e normaliza start UTC', () async {
    await f.api.generateStudyPlan(
        horizonDays: 7,
        timezoneOffsetMinutes: -180,
        startAt: DateTime.parse('2026-09-07T19:00:00-03:00'));
    expect(jsonDecode(f.requests.single.body), {
      'horizon_days': 7,
      'timezone_offset_minutes': -180,
      'start_at': '2026-09-07T22:00:00.000Z',
    });
  });

  for (final corrupt in ['risk', 'date', 'summary']) {
    test('resposta inválida do Planner é sanitizada: $corrupt', () async {
      final data = planJson();
      if (corrupt == 'risk') (data['tasks'] as List).single['risk'] = 'unknown';
      if (corrupt == 'date') data['generated_at'] = 'bad';
      if (corrupt == 'summary') data['summary'] = null;
      f.intercept = (_) => jsonResponse(data);
      await expectLater(
          f.api.generateStudyPlan(), throwsA(isA<ApiException>()));
    });
  }

  test('loading impede duplicação e termina após sucesso', () async {
    final gate = Completer<http.Response>();
    f.intercept = (_) => gate.future;
    final pending = f.app.generateStudyPlan();
    await f.app.generateStudyPlan();
    expect(f.app.isGeneratingPlan, isTrue);
    gate.complete(jsonResponse(planJson()));
    await pending;
    expect(f.requests.length, 1);
    expect(f.app.isGeneratingPlan, isFalse);
    expect(f.app.studyPlan, isNotNull);
    expect(f.app.planError, isNull);
  });

  test('falha preserva plano anterior, retry substitui e limpa erro', () async {
    await f.app.generateStudyPlan();
    final previous = f.app.studyPlan;
    f.intercept = (_) => jsonResponse({}, 500);
    await f.app.generateStudyPlan();
    expect(f.app.studyPlan, same(previous));
    expect(f.app.planError, 'Não foi possível gerar o plano de estudos.');
    expect(f.app.isGeneratingPlan, isFalse);
    f.intercept = null;
    await f.app.generateStudyPlan();
    expect(f.app.studyPlan, isNot(same(previous)));
    expect(f.app.planError, isNull);
  });

  for (final operation in [
    'task edit',
    'completion',
    'task delete',
    'task create',
    'slot edit',
    'slot delete',
    'slot create',
    'subject edit',
    'load'
  ]) {
    test('$operation invalida plano após confirmação', () async {
      await f.app.loadData();
      await f.app.generateStudyPlan();
      expect(f.app.studyPlan, isNotNull);
      switch (operation) {
        case 'task edit':
          await f.app.updateTask('task-a', estimatedMinutes: 120);
        case 'completion':
          await f.app.toggleTaskCompletion('task-a');
        case 'task delete':
          await f.app.deleteTask('task-a');
        case 'task create':
          await f.app.addTask(
              title: 'Nova',
              subjectId: 'subject-a',
              estimatedMinutes: 30,
              dueDate: DateTime.utc(2026, 9, 10));
        case 'slot edit':
          await f.app.updateAvailabilityRepeat('slot-a', false);
        case 'slot delete':
          await f.app.deleteAvailabilitySlot('slot-a');
        case 'slot create':
          await f.app.addAvailabilitySlot(
              dayOfWeek: 1,
              startTime: '19:00',
              endTime: '20:00',
              repeatNextWeek: true);
        case 'subject edit':
          await f.app.updateSubject('subject-a', name: 'Novo nome');
        case 'load':
          await f.app.loadData();
      }
      expect(f.app.studyPlan, isNull);
    });
  }

  test('dica local e mutação rejeitada preservam plano', () async {
    await f.app.loadData();
    await f.app.generateStudyPlan();
    final previous = f.app.studyPlan;
    f.app.setTaskAiTip('task-a', 'Dica');
    expect(f.app.studyPlan, same(previous));
    f.intercept = (_) => jsonResponse({}, 500);
    await expectLater(
        f.app.toggleTaskCompletion('task-a'), throwsA(isA<ApiException>()));
    expect(f.app.studyPlan, same(previous));
  });

  test('plano atrasado após CRUD não substitui plano mais recente', () async {
    await f.app.loadData();
    final gate = Completer<http.Response>();
    f.intercept =
        (r) => r.url.path.endsWith('/planner/plan') ? gate.future : null;
    final pending = f.app.generateStudyPlan();
    await f.app.toggleTaskCompletion('task-a');
    f.intercept = null;
    await f.app.generateStudyPlan();
    final fresh = f.app.studyPlan;
    gate.complete(jsonResponse({...planJson(), 'blocks': []}));
    await pending;
    expect(f.app.studyPlan, same(fresh));
    expect(f.app.isGeneratingPlan, isFalse);
  });

  for (final responseCode in [200, 500, 401]) {
    test('plano atrasado após logout ignora resposta $responseCode', () async {
      await f.auth.initialize();
      await f.auth.login('a@example.com', 'fictitious-password');
      await f.settle();
      final gate = Completer<http.Response>();
      f.intercept =
          (r) => r.url.path.endsWith('/planner/plan') ? gate.future : null;
      final pending = f.app.generateStudyPlan();
      await f.auth.logout();
      await f.auth.login('b@example.com', 'fictitious-password');
      await f.settle();
      gate.complete(jsonResponse(planJson(), responseCode));
      await pending;
      expect(f.app.studyPlan, isNull);
      expect(f.app.planError, isNull);
      expect(f.auth.currentUser!.id, 'user-b');
    });
  }
}
