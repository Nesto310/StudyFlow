import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'app_state.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthState extends ChangeNotifier {
  AuthState(
      {required ApiClient apiClient,
      required TokenStorage tokenStorage,
      required AppState appState,
      bool demoMode = false})
      : _api = apiClient,
        _storage = tokenStorage,
        _app = appState,
        _demoMode = demoModeForBuild(requested: demoMode) {
    _api.onUnauthorized = () => logout(expired: true);
  }

  final ApiClient _api;
  final TokenStorage _storage;
  final AppState _app;
  final bool _demoMode;
  bool _demoStartupAllowed = true;
  bool _initializingDemo = false;
  bool _isDemoSession = false;
  bool get isDemoSession => _isDemoSession;
  AuthStatus status = AuthStatus.initializing;
  UserModel? currentUser;
  String? error;
  bool isBusy = false;
  bool _disposed = false;
  bool _pendingLogout = false;
  int _generation = 0;
  Future<void> _storageQueue = Future.value();

  // A pending login write must finish before logout deletes the stored token.
  Future<T> _stored<T>(Future<T> Function() operation) {
    final result = _storageQueue.then((_) => operation());
    _storageQueue =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (isBusy || _disposed) return;
    if (_pendingLogout) {
      await logout();
      return;
    }
    final generation = ++_generation;
    status = AuthStatus.initializing;
    isBusy = true;
    error = null;
    currentUser = null;
    _app.clear();
    _notify();
    try {
      _initializingDemo = _demoMode && _demoStartupAllowed;
      final token = _initializingDemo
          ? await _api.startDemoSession()
          : await _stored(_storage.readToken);
      if (!_isCurrent(generation)) return;
      if (token == null || token.isEmpty) {
        _api.setToken(null);
        status = AuthStatus.unauthenticated;
      } else {
        await _acceptToken(token, generation, demo: _initializingDemo);
      }
    } on ApiException catch (exception) {
      if (_isCurrent(generation)) {
        _api.setToken(null);
        error = _initializingDemo
            ? 'Não foi possível iniciar a demonstração. Confira o backend de desenvolvimento e tente novamente.'
            : exception.message;
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        error = 'Não foi possível acessar sua sessão salva. Tente novamente.';
      }
    } finally {
      if (_isCurrent(generation)) {
        _initializingDemo = false;
        isBusy = false;
        _notify();
      }
    }
  }

  Future<void> login(String email, String password) =>
      _authenticate(email, password, register: false);

  Future<void> register(String email, String password) =>
      _authenticate(email, password, register: true);

  Future<void> _acceptToken(String token, int generation,
      {bool persist = false, bool demo = false}) async {
    if (!_isCurrent(generation)) return;
    _api.setToken(token);
    final user = await _api.getCurrentUser();
    if (!_isCurrent(generation)) return;
    if (persist) {
      await _stored(() => _storage.saveToken(token));
      if (!_isCurrent(generation)) return;
    }
    currentUser = user;
    _isDemoSession = demo;
    status = AuthStatus.authenticated;
    unawaited(_app.loadData());
  }

  Future<void> _authenticate(String email, String password,
      {required bool register}) async {
    if (isBusy || _disposed || status != AuthStatus.unauthenticated) return;
    final generation = ++_generation;
    isBusy = true;
    error = null;
    _app.clear();
    _notify();
    try {
      if (register) {
        await _api.register(email, password);
        if (!_isCurrent(generation)) return;
      }
      final token = await _api.login(email, password);
      await _acceptToken(token, generation, persist: true);
    } on ApiException catch (exception) {
      if (_isCurrent(generation)) {
        _api.setToken(null);
        error = exception.message;
      }
    } catch (_) {
      if (_isCurrent(generation)) {
        await logout();
        if (!_disposed && !_pendingLogout) {
          error =
              'Não foi possível salvar sua sessão com segurança. Tente novamente.';
          _notify();
        }
      }
    } finally {
      if (_isCurrent(generation)) {
        isBusy = false;
        _notify();
      }
    }
  }

  Future<void> logout({bool expired = false}) async {
    if (_disposed) return;
    final generation = ++_generation;
    final demo = _isDemoSession || _initializingDemo;
    _demoStartupAllowed = false;
    _initializingDemo = false;
    _isDemoSession = false;
    _api.setToken(null);
    currentUser = null;
    status = AuthStatus.unauthenticated;
    isBusy = true;
    error = expired ? 'Sua sessão terminou. Entre novamente.' : null;
    _app.clear();
    _notify();
    try {
      // Demo tokens live only in memory; leave a saved real session untouched.
      if (!demo) await _stored(_storage.deleteToken);
      if (_isCurrent(generation)) _pendingLogout = false;
    } catch (_) {
      if (_isCurrent(generation)) {
        _pendingLogout = true;
        status = AuthStatus.initializing;
        error =
            'Não foi possível apagar a sessão salva. Tente novamente para concluir a saída.';
      }
    } finally {
      if (_isCurrent(generation)) {
        isBusy = false;
        _notify();
      }
    }
  }

  void clearError() {
    error = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _api.onUnauthorized = null;
    super.dispose();
  }
}
