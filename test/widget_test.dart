import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyflow/main.dart';
import 'package:studyflow/screens/auth/auth_screen.dart';
import 'package:studyflow/screens/main_navigation_screen.dart';

import 'support/api_fixture.dart';

Finder filledButton(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );

Future<void> openApp(WidgetTester tester, ApiFixture f) async {
  await tester
      .pumpWidget(StudyFlowApp(apiClient: f.api, tokenStorage: f.storage));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aplicativo sem sessão mostra login', (tester) async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await openApp(tester, f);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(f.requests, isEmpty);
  });

  testWidgets('sessão autenticada abre navegação principal anterior',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await openApp(tester, f);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final title in [
      'Tarefas',
      'Disciplinas',
      'Horários',
      'Cursos',
      'Perfil'
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Tarefa a'), findsOneWidget);
  });

  testWidgets('login tem validação, oculta senha e impede submit duplicado',
      (tester) async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await openApp(tester, f);
    await tester.tap(filledButton('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu email.'), findsOneWidget);
    expect(find.text('Use entre 8 e 128 caracteres.'), findsOneWidget);
    final password = tester.widgetList<TextField>(find.byType(TextField)).last;
    expect(password.obscureText, isTrue);
    await tester.enterText(find.byType(TextFormField).at(0), 'a@example.com');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'fictitious-password');
    final gate = Completer<http.Response>();
    f.intercept =
        (r) => r.url.path.endsWith('/auth/token') ? gate.future : null;
    await tester.tap(filledButton('Entrar'));
    await tester.pump();
    expect(
        tester.widget<FilledButton>(filledButton('Entrar')).onPressed, isNull);
    gate.complete(jsonResponse(
        {'access_token': 'fictitious-token-a', 'token_type': 'bearer'}));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
    expect(
        f.requests.where((r) => r.url.path.endsWith('/auth/token')).length, 1);
  });

  testWidgets('registro exige confirmação igual e faz login automático',
      (tester) async {
    final f = ApiFixture(seeded: false);
    addTearDown(f.dispose);
    await openApp(tester, f);
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'a@example.com');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'fictitious-password');
    await tester.enterText(
        find.byType(TextFormField).at(2), 'different-password');
    await tester.tap(filledButton('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas devem ser iguais.'), findsOneWidget);
    expect(f.requests, isEmpty);
    await tester.enterText(
        find.byType(TextFormField).at(2), 'fictitious-password');
    await tester.tap(filledButton('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma tarefa cadastrada.'), findsOneWidget);
    expect(f.storage.token, 'fictitious-token-a');
  });

  testWidgets('erro de restauração mostra retry sem apagar token',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    f.intercept = (_) => throw http.ClientException('offline');
    await openApp(tester, f);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
    expect(f.storage.token, isNotNull);
    f.intercept = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('erro ao carregar dados mostra retry e nenhum dado parcial',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    f.intercept =
        (r) => r.url.path.endsWith('/tasks') ? jsonResponse({}, 500) : null;
    await openApp(tester, f);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Tarefa a'), findsNothing);
    f.intercept = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa a'), findsOneWidget);
  });

  testWidgets('perfil mostra email e logout volta para login', (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await openApp(tester, f);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('a@example.com'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Tarefa a'), findsNothing);
    expect(f.storage.token, isNull);
  });

  testWidgets('criação de disciplina aguarda API e bloqueia botão',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a', seeded: false);
    addTearDown(f.dispose);
    await openApp(tester, f);
    await tester.tap(find.text('Disciplinas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova Disciplina'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Álgebra');
    final gate = Completer<http.Response>();
    f.intercept = (r) => r.method == 'POST' ? gate.future : null;
    await tester.tap(find.text('Adicionar Disciplina'));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(filledButton('Adicionar Disciplina'))
            .onPressed,
        isNull);
    gate.complete(jsonResponse({...subjectJson(), 'name': 'Álgebra'}, 201));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Álgebra'), findsOneWidget);
  });

  testWidgets('401 em formulário elimina modal da sessão anterior',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await openApp(tester, f);
    await tester.tap(find.text('Disciplinas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova Disciplina'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Privada');
    f.intercept = (r) => r.method == 'POST' ? jsonResponse({}, 401) : null;
    await tester.tap(find.text('Adicionar Disciplina'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Adicionar Disciplina'), findsNothing);
    expect(find.text('Privada'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nova tarefa exige data/hora e usa pickers antes do POST',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openApp(tester, f);
    await tester.tap(find.text('Nova Tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tarefa real');
    await tester.tap(find.text('Adicionar Tarefa'));
    await tester.pumpAndSettle();
    expect(
        find.text('Selecione a data e o horário de entrega.'), findsOneWidget);
    await tester.tap(find.text('Data de entrega'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horário de entrega'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar Tarefa'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa real'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('cria horário vazio e confirma exclusão antes de enviar DELETE',
      (tester) async {
    final f = ApiFixture(savedToken: 'fictitious-token-a', seeded: false);
    addTearDown(f.dispose);
    await openApp(tester, f);
    await tester.tap(find.text('Horários'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum horário disponível cadastrado.'), findsOneWidget);
    await tester.tap(find.text('Novo Horário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar Horário'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Excluir horário'), findsOneWidget);
    await tester.tap(find.byTooltip('Excluir horário'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(f.requests.where((r) => r.method == 'DELETE'), isEmpty);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Excluir horário'), findsOneWidget);
    await tester.tap(find.byTooltip('Excluir horário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum horário disponível cadastrado.'), findsOneWidget);
  });

  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets(
        'telas e formulários sem overflow em ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = ApiFixture(savedToken: 'fictitious-token-a');
      addTearDown(f.dispose);
      f.rows['a']!['subjects']!.single['name'] =
          'Nome de disciplina suficientemente longo para ocupar mais de uma linha';
      await openApp(tester, f);
      expect(tester.takeException(), isNull);
      for (final entry in {
        'Tarefas': 'Nova Tarefa',
        'Disciplinas': 'Nova Disciplina',
        'Horários': 'Novo Horário'
      }.entries) {
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.value));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(MainNavigationScreen));
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
