import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'token';
  static const _keyServer = 'server';
  static const _keyUserId = 'userId';

  static Future<void> saveAuth({
    required String token,
    required String server,
    required String userId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyServer, value: server);
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<String?> get token => _storage.read(key: _keyToken);
  static Future<String?> get server => _storage.read(key: _keyServer);
  static Future<String?> get userId => _storage.read(key: _keyUserId);

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
