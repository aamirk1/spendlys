import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spendly/core/services/encryption_service.dart';

class LocalCacheService {
  static const String _cacheBoxName = 'api_cache';
  static const String _pendingSyncBoxName = 'pending_sync';

  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final encryptionKey = await EncryptionService.getOrCreateEncryptionKey();
    
    await Hive.initFlutter(directory.path);
    await Hive.openBox(_cacheBoxName, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(_pendingSyncBoxName, encryptionCipher: HiveAesCipher(encryptionKey));
  }

  // --- API Cache Methods ---

  static Future<void> setCache(String key, dynamic data) async {
    final box = Hive.box(_cacheBoxName);
    await box.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static dynamic getCache(String key) {
    final box = Hive.box(_cacheBoxName);
    final cached = box.get(key);
    if (cached != null) {
      return cached['data'];
    }
    return null;
  }

  static Future<void> clearCache() async {
    await Hive.box(_cacheBoxName).clear();
  }

  // --- Pending Sync Methods ---

  static Future<void> addPendingRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final box = Hive.box(_pendingSyncBoxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'headers': headers,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static List<Map<String, dynamic>> getAllPendingRequests() {
    final box = Hive.box(_pendingSyncBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> removePendingRequest(String id) async {
    await Hive.box(_pendingSyncBoxName).delete(id);
  }
}
