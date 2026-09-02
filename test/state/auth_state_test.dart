import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyflow/services/api_client.dart';
import 'package:studyflow/state/auth_state.dart';

import '../support/api_fixture.dart';

void main() {
  test('sem token salvo abre sessão não autenticada, sem rede', () async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await f.auth.initialize();
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.requests, isEmpty);
    expect(f.app.subjects, isEmpty);
  });

  test('token salvo e /me 200 restauram usuário e carregam dados', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    expect(f.auth.status, AuthStatus.authenticated);
    expect(f.auth.currentUser!.email, 'a@example.com');
    expect(f.app.subjects.single.id, 'subject-a');
    expect(f.storage.saves, 0);
  });

  test('token salvo e /me 401 apagam token e dados', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    f.intercept = (_) => jsonResponse({}, 401);
    await f.auth.initialize();
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.auth.currentUser, isNull);
    expect(f.storage.token, isNull);
    expect(f.app.subjects, isEmpty);
    expect(f.auth.error, contains('sessão terminou'));
  });

  test('erro de conexão na restauração mantém token e permite retry', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    f.intercept = (_) => throw http.ClientException('offline');
    await f.auth.initialize();
    expect(f.auth.status, AuthStatus.initializing);
    expect(f.auth.error, contains('conectar'));
    expect(f.storage.token, 'fictitious-token-a');
    expect(f.storage.deletes, 0);
    f.intercept = null;
    await f.auth.initialize();
    await f.settle();
    expect(f.auth.status, AuthStatus.authenticated);
    expect(f.auth.error, isNull);
  });

  test('login válido salva somente token e busca usuário', () async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.auth.login('a@example.com', 'fictitious-password');
    await f.settle();
    expect(f.storage.token, 'fictitious-token-a');
    expect(f.storage.saves, 1);
    expect(f.auth.currentUser!.id, 'user-a');
    expect(f.auth.isBusy, isFalse);
  });

  test('registro faz login automático e carrega dados', () async {
    final f = ApiFixture(seeded: false);
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.auth.register('a@example.com', 'fictitious-password');
    await f.settle();
    expect(f.requests.take(3).map((r) => r.url.path), [
      '/api/v1/auth/register',
      '/api/v1/auth/token',
      '/api/v1/users/me',
    ]);
    expect(f.auth.status, AuthStatus.authenticated);
    expect(f.app.hasLoaded, isTrue);
    expect(f.app.tasks, isEmpty);
  });

  test('login 401 não é tratado como expiração nem apaga storage', () async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await f.auth.initialize();
    f.intercept = (_) => jsonResponse({}, 401);
    await f.auth.login('a@example.com', 'fictitious-password');
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.auth.error, 'Email ou senha incorretos.');
    expect(f.storage.deletes, 0);
  });

  test('logout limpa dados e identidade imediatamente', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    final pending = f.auth.logout();
    expect(f.auth.currentUser, isNull);
    expect(f.app.subjects, isEmpty);
    expect(f.app.tasks, isEmpty);
    expect(f.app.availabilitySlots, isEmpty);
    expect(f.app.hasLoaded, isFalse);
    await pending;
    expect(f.storage.token, isNull);
    await expectLater(f.api.getCurrentUser(), throwsA(isA<ApiException>()));
  });

  test('401 durante uso encerra sessão e elimina dados acadêmicos', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    f.intercept = (_) => jsonResponse({}, 401);
    await expectLater(
        f.app.toggleTaskCompletion('task-a'), throwsA(isA<ApiException>()));
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.storage.token, isNull);
    expect(f.app.tasks, isEmpty);
    expect(f.app.subjects, isEmpty);
  });

  test('401 paralelos encerram sessão uma única vez', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    f.intercept = (_) => jsonResponse({}, 401);
    await f.app.loadData();
    expect(f.storage.deletes, 1);
    expect(f.app.loadError, isNull);
    expect(f.auth.status, AuthStatus.unauthenticated);
  });

  test('troca de usuários A -> logout -> B nunca mantém dados A', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    expect(f.app.tasks.single.id, 'task-a');
    await f.auth.logout();
    expect(f.app.subjects, isEmpty);
    expect(f.app.tasks, isEmpty);
    expect(f.app.availabilitySlots, isEmpty);
    var checkedDuringLoading = false;
    f.app.addListener(() {
      if (f.app.isLoading) {
        checkedDuringLoading = true;
        expect(f.app.subjects, isEmpty);
        expect(f.app.tasks, isEmpty);
        expect(f.app.availabilitySlots, isEmpty);
      }
    });
    await f.auth.login('b@example.com', 'fictitious-password');
    await f.settle();
    expect(checkedDuringLoading, isTrue);
    expect(f.auth.currentUser!.id, 'user-b');
    expect(f.app.subjects.single.id, 'subject-b');
    expect(f.app.tasks.single.id, 'task-b');
    expect(f.app.availabilitySlots.single.id, 'slot-b');
  });

  test('resposta 401 atrasada de A não encerra a nova sessão B', () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    final gate = Completer<http.Response>();
    final started = Completer<void>();
    f.intercept = (request) {
      if (request.headers['Authorization'] == 'Bearer fictitious-token-a') {
        if (!started.isCompleted) started.complete();
        return gate.future;
      }
      return null;
    };
    final old = f.api.getSubjects();
    final assertion = expectLater(old, throwsA(isA<ApiException>()));
    await started.future;
    await f.auth.logout();
    await f.auth.login('b@example.com', 'fictitious-password');
    await f.settle();
    gate.complete(jsonResponse({}, 401));
    await assertion;
    expect(f.auth.currentUser!.id, 'user-b');
    expect(f.storage.token, 'fictitious-token-b');
    expect(f.app.tasks.single.id, 'task-b');
  });

  test('logout durante gravação de token não ressuscita sessão salva',
      () async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await f.auth.initialize();
    f.storage.saveGate = Completer<void>();
    final login = f.auth.login('a@example.com', 'fictitious-password');
    while (f.storage.saves == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    final logout = f.auth.logout();
    f.storage.saveGate!.complete();
    await Future.wait([login, logout]);
    expect(f.storage.token, isNull);
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.app.tasks, isEmpty);
  });

  test('falha ao salvar token não deixa sessão autenticada', () async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await f.auth.initialize();
    f.storage.failSave = true;
    await f.auth.login('a@example.com', 'fictitious-password');
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.storage.token, isNull);
    expect(f.auth.error, contains('segurança'));
    expect(f.app.tasks, isEmpty);
  });

  test('falha ao apagar token bloqueia restauração até concluir logout',
      () async {
    final f = ApiFixture(savedToken: 'fictitious-token-a');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    f.storage.failDelete = true;
    await f.auth.logout();
    expect(f.auth.status, AuthStatus.initializing);
    expect(f.auth.currentUser, isNull);
    expect(f.app.tasks, isEmpty);
    f.storage.failDelete = false;
    await f.auth.initialize();
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.storage.token, isNull);
  });

  test('login concorrente é enviado uma única vez', () async {
    final f = ApiFixture();
    addTearDown(f.dispose);
    await f.auth.initialize();
    await Future.wait([
      f.auth.login('a@example.com', 'fictitious-password'),
      f.auth.login('a@example.com', 'fictitious-password'),
    ]);
    await f.settle();
    expect(
        f.requests.where((r) => r.url.path.endsWith('/auth/token')).length, 1);
  });
}
