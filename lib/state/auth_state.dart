import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'app_state.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthState extends ChangeNotifier {
  AuthState(
      {required ApiClient apiClient,
      required TokenStorage tokenStorage,
      required AppState appState})
      : _api = apiClient,
        _storage = tokenStorage,
        _app = appState {
    _api.onUnauthorized = () => logout(expired: true);
  }

  final ApiClient _api;
  final TokenStorage _storage;
  final AppState _app;
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
      final token = await _stored(_storage.readToken);
      if (!_isCurrent(generation)) return;
      _api.setToken(token);
      if (token == null || token.isEmpty) {
        _api.setToken(null);
        status = AuthStatus.unauthenticated;
      } else {
        final user = await _api.getCurrentUser();
        if (!_isCurrent(generation)) return;
        currentUser = user;
        status = AuthStatus.authenticated;
        unawaited(_app.loadData());
      }
    } on ApiException catch (exception) {
      if (_isCurrent(generation)) error = exception.message;
    } catch (_) {
      if (_isCurrent(generation)) {
        error = 'Não foi possível acessar sua sessão salva. Tente novamente.';
      }
    } finally {
      if (_isCurrent(generation)) {
        isBusy = false;
        _notify();
      }
    }
  }

  Future<void> login(String email, String password) =>
      _authenticate(email, password, register: false);

  Future<void> register(String email, String password) =>
      _authenticate(email, password, register: true);

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
      if (!_isCurrent(generation)) return;
      _api.setToken(token);
      final user = await _api.getCurrentUser();
      if (!_isCurrent(generation)) return;
      await _stored(() => _storage.saveToken(token));
      if (!_isCurrent(generation)) return;
      currentUser = user;
      status = AuthStatus.authenticated;
      unawaited(_app.loadData());
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
    _api.setToken(null);
    currentUser = null;
    status = AuthStatus.unauthenticated;
    isBusy = true;
    error = expired ? 'Sua sessão terminou. Entre novamente.' : null;
    _app.clear();
    _notify();
    try {
      await _stored(_storage.deleteToken);
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
