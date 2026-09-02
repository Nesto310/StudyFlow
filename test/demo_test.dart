import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyflow/config/app_config.dart';
import 'package:studyflow/state/auth_state.dart';

import 'support/api_fixture.dart';

void main() {
  test('demo exige debug mesmo quando explicitamente solicitado', () {
    expect(demoModeForBuild(debugBuild: false, requested: true), isFalse);
    expect(demoModeForBuild(debugBuild: false, requested: false), isFalse);
    expect(demoModeForBuild(debugBuild: true, requested: false), isFalse);
    expect(demoModeForBuild(debugBuild: true, requested: true), kDebugMode);
  });

  test('demo usa POST sem credenciais, /me e carga normal sem persistir',
      () async {
    final f = ApiFixture(demoMode: true);
    addTearDown(f.dispose);
    f.storage.failRead = true;
    f.storage.failSave = true;
    await f.auth.initialize();
    await f.settle();
    expect(f.auth.status, AuthStatus.authenticated);
    expect(f.auth.isDemoSession, isTrue);
    expect(f.app.tasks, isNotEmpty);
    final request = f.requests.first;
    expect(request.url.path, '/api/v1/dev/demo-session');
    expect(request.method, 'POST');
    expect(request.body, isEmpty);
    expect(request.headers['Authorization'], isNull);
    expect(f.requests[1].headers['Authorization'],
        'Bearer fictitious-demo-token-a');
    expect(f.storage.saves, 0);
    expect(f.storage.token, isNull);
  });

  test('demo não substitui sessão real salva nem a apaga ao sair', () async {
    final f = ApiFixture(demoMode: true, savedToken: 'fictitious-token-b');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    expect(f.auth.currentUser!.id, 'user-a');
    await f.auth.logout();
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.auth.isDemoSession, isFalse);
    expect(f.storage.token, 'fictitious-token-b');
    expect(f.storage.deletes, 0);
    expect(f.app.tasks, isEmpty);
    expect(f.requests.where((r) => r.url.path.endsWith('/demo-session')).length,
        1);
    await f.auth.login('b@example.com', 'fictitious-password');
    await f.settle();
    expect(f.auth.isDemoSession, isFalse);
    expect(f.storage.saves, 1);
    await f.auth.logout();
    expect(f.storage.token, isNull);
  });

  test('falha demo permite retry sem fallback silencioso para conta salva',
      () async {
    final f = ApiFixture(demoMode: true, savedToken: 'fictitious-token-b');
    addTearDown(f.dispose);
    f.intercept = (_) => jsonResponse({}, 404);
    await f.auth.initialize();
    expect(f.auth.status, AuthStatus.initializing);
    expect(f.auth.error, contains('demonstração'));
    expect(f.auth.currentUser, isNull);
    expect(f.storage.token, 'fictitious-token-b');
    f.intercept = null;
    await f.auth.initialize();
    await f.settle();
    expect(f.auth.isDemoSession, isTrue);
  });

  test('resposta demo atrasada após logout não autentica novamente', () async {
    final f = ApiFixture(demoMode: true);
    addTearDown(f.dispose);
    final gate = Completer<http.Response>();
    f.intercept = (_) => gate.future;
    final pending = f.auth.initialize();
    await f.auth.logout();
    gate.complete(jsonResponse(
        {'access_token': 'fictitious-demo-token-a', 'token_type': 'bearer'}));
    await pending;
    expect(f.auth.status, AuthStatus.unauthenticated);
    expect(f.auth.currentUser, isNull);
    expect(f.app.tasks, isEmpty);
    expect(f.storage.saves, 0);
  });

  test('demo false preserva restauração da sessão real', () async {
    final f = ApiFixture(demoMode: false, savedToken: 'fictitious-token-b');
    addTearDown(f.dispose);
    await f.auth.initialize();
    await f.settle();
    expect(f.auth.currentUser!.id, 'user-b');
    expect(f.auth.isDemoSession, isFalse);
    expect(
        f.requests.where((r) => r.url.path.endsWith('/demo-session')), isEmpty);
  });
}
