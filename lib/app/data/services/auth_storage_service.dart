import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorageService {
  final _storage = const FlutterSecureStorage();

  static const String _keyUserId = 'auth_flow_user_id';

  // Save User UID
  Future<void> saveUser(String uid) async {
    await _storage.write(key: _keyUserId, value: uid);
  }

  // Get User UID
  Future<String?> getUser() async {
    return await _storage.read(key: _keyUserId);
  }

  // Clear User Session
  Future<void> clearUser() async {
    await _storage.delete(key: _keyUserId);
  }
}
