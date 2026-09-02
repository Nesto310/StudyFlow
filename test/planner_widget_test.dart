import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyflow/main.dart';
import 'package:studyflow/models/study_plan_model.dart';
import 'package:studyflow/screens/auth/auth_screen.dart';
import 'package:studyflow/screens/availability/planner_preview.dart';

import 'support/api_fixture.dart';
import 'widget_test.dart' show openApp, filledButton;

void main() {
  testWidgets('debug demo abre dados sem AuthScreen, identifica Perfil e sai',
      (tester) async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    // No override: exercise the temporary debug default in the real root widget.
    await tester
        .pumpWidget(StudyFlowApp(apiClient: f.api, tokenStorage: f.storage));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsNothing);
    expect(find.text('Tarefa a'), findsOneWidget);
    expect(f.requests.first.url.path, '/api/v1/dev/demo-session');
    expect(f.storage.token, isNull);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Modo demonstração'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(f.requests.where((r) => r.url.path.endsWith('/demo-session')).length,
        1);
  });

  testWidgets('Planner loading, erro preserva preview e retry funciona',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await openApp(tester, f);
    await tester.tap(find.text('Horários'));
    await tester.pumpAndSettle();
    final gate = Completer<http.Response>();
    f.intercept = (_) => gate.future;
    await tester.tap(find.text('Gerar plano de estudos'));
    await tester.pump();
    expect(
        tester.widget<FilledButton>(filledButton('Gerando plano...')).onPressed,
        isNull);
    gate.complete(jsonResponse(planJson()));
    await tester.pumpAndSettle();
    expect(find.text('Plano dos próximos 14 dias'), findsOneWidget);
    expect(find.text('Revisar árvores AVL'), findsOneWidget);
    f.intercept = (_) => jsonResponse({}, 500);
    await tester.tap(find.text('Gerar plano de estudos'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível gerar o plano de estudos.'),
        findsOneWidget);
    expect(find.text('Revisar árvores AVL'), findsOneWidget);
    f.intercept = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(
        find.text('Não foi possível gerar o plano de estudos.'), findsNothing);
    expect(find.text('Revisar árvores AVL'), findsOneWidget);
  });

  for (final scenario in ['no tasks', 'no availability', 'risks', 'on track']) {
    testWidgets('preview apresenta $scenario', (tester) async {
      final data = planJson();
      final summary = data['summary'] as Map<String, dynamic>;
      if (scenario == 'no tasks') {
        data['blocks'] = [];
        data['tasks'] = [];
        summary['total_pending_tasks'] = 0;
      } else if (scenario == 'no availability') {
        data['blocks'] = [];
        summary['total_available_minutes'] = 0;
        summary['on_track_tasks'] = 0;
        summary['at_risk_tasks'] = 1;
      } else if (scenario == 'risks') {
        summary['total_pending_tasks'] = 2;
        summary['on_track_tasks'] = 0;
        summary['at_risk_tasks'] = 1;
        summary['overdue_tasks'] = 1;
      }
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: PlannerPreview(plan: StudyPlan.fromJson(data))))));
      if (scenario == 'no tasks') {
        expect(find.text('Você não possui tarefas pendentes para planejar.'),
            findsOneWidget);
      } else if (scenario == 'no availability') {
        expect(find.text('Cadastre horários disponíveis para gerar seu plano.'),
            findsOneWidget);
      } else if (scenario == 'risks') {
        expect(
            find.text(
                'Não há tempo suficiente disponível antes do prazo de 1 tarefa.'),
            findsOneWidget);
        expect(find.text('Você possui 1 tarefa atrasada no plano.'),
            findsOneWidget);
      } else {
        expect(
            find.text(
                'Todas as tarefas pendentes cabem na sua disponibilidade atual.'),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('preview usa datas/horas locais sem overflow em $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = planJson();
      final block = (data['blocks'] as List).single as Map<String, dynamic>;
      block['subject_name'] =
          'Disciplina com nome suficientemente longo para ocupar várias linhas';
      block['task_title'] =
          'Revisar árvores e resolver os exercícios da próxima avaliação';
      final plan = StudyPlan.fromJson(data);
      final local = plan.blocks.single.startAt.toLocal();
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PlannerPreview(plan: plan))))));
      final date =
          '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      final time =
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      expect(find.textContaining(date), findsOneWidget);
      expect(find.textContaining(time), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
