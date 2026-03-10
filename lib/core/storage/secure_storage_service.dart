import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  // Keys
  static const String _keyToken = 'auth_token';
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';

  // Auth Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // User Credentials
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    String? email = await _storage.read(key: _keyEmail);
    String? password = await _storage.read(key: _keyPassword);
    return {'email': email, 'password': password};
  }

  // Clear Storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }
}
