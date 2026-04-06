import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';

  static Future<Uint8List> getOrCreateEncryptionKey() async {
    final keyString = await _storage.read(key: _keyName);
    if (keyString != null) {
      return base64Decode(keyString);
    } else {
      final key = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64UrlEncode(key));
      return Uint8List.fromList(key);
    }
  }
}
