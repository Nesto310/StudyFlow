import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'studyflow_access_token';

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _key);
}
