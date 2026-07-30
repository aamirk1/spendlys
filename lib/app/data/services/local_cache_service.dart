import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spendly/app/data/services/encryption_service.dart';

class LocalCacheService {
  static const String _cacheBoxName = 'api_cache';
  static const String _pendingSyncBoxName = 'pending_sync';

  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final encryptionKey = await EncryptionService.getOrCreateEncryptionKey();

    await Hive.initFlutter(directory.path);
    await Hive.openBox(_cacheBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(_pendingSyncBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey));
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

  static Future<void> updateMatchingListCaches({
    required String endpoint,
    required String method,
    dynamic body,
    String? id,
  }) async {
    var resourcePath = endpoint.split('?')[0];
    if (resourcePath.startsWith('/')) {
      resourcePath = resourcePath.substring(1);
    }
    if (resourcePath.endsWith('/')) {
      resourcePath = resourcePath.substring(0, resourcePath.length - 1);
    }

    final parts = resourcePath.split('/');
    String baseResource = resourcePath;
    String? itemId = id;

    if (parts.length > 1 && method != 'POST') {
      if (parts[0] == 'business' && parts.length == 3) {
        baseResource = '${parts[0]}/${parts[1]}';
        itemId = parts[2];
      } else if (parts[0] != 'business' && parts.length == 2) {
        baseResource = parts[0];
        itemId = parts[1];
      }
    }

    final box = Hive.box(_cacheBoxName);
    final keys = List<String>.from(box.keys.map((e) => e.toString()));

    for (final key in keys) {
      final cleanKey = key.replaceFirst('GET_/', '');
      final cleanKeyPath = cleanKey.split('?')[0].replaceAll(RegExp(r'/$'), '');

      if (cleanKeyPath == baseResource) {
        final cached = box.get(key);
        if (cached != null && cached['data'] != null) {
          var data = cached['data'];

          if (data is List) {
            final list = List<Map<String, dynamic>>.from(
              data.map((e) => Map<String, dynamic>.from(e))
            );

            if (method == 'POST') {
              final newItem = Map<String, dynamic>.from(body ?? {});
              if (!newItem.containsKey('id') || newItem['id'] == null) {
                newItem['id'] = itemId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
              }
              newItem['status'] = 'syncing';

              bool shouldAdd = true;
              if (baseResource == 'transactions') {
                final String? type = newItem['type'];
                if (type != null) {
                  if (cleanKey.contains('type=$type')) {
                    shouldAdd = true;
                  } else if (cleanKey.contains('type=')) {
                    shouldAdd = false;
                  }
                }
              }

              if (shouldAdd) {
                list.insert(0, newItem);
              }
            } else if (method == 'PUT' || method == 'PATCH') {
              if (itemId != null) {
                final index = list.indexWhere((e) => e['id']?.toString() == itemId);
                if (index != -1) {
                  list[index] = {
                    ...list[index],
                    ...(body ?? {}),
                    'status': 'syncing',
                  };
                }
              }
            } else if (method == 'DELETE') {
              if (itemId != null) {
                list.removeWhere((e) => e['id']?.toString() == itemId);
              }
            }

            await box.put(key, {
              'data': list,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          } else if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
              final updatedMap = {
                ...map,
                ...(body ?? {}),
              };
              await box.put(key, {
                'data': updatedMap,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        }
      }
    }
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
