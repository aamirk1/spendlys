import 'package:get/get.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/core/services/connectivity_service.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';

class SyncService extends GetxService {
  final _isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Periodically try to sync if online
    Timer.periodic(const Duration(minutes: 5), (_) => startSync());
  }

  Future<void> startSync() async {
    final connectivity = Get.find<ConnectivityService>();
    if (!connectivity.isOnline.value || _isSyncing.value) return;

    final pendingRequests = LocalCacheService.getAllPendingRequests();
    if (pendingRequests.isEmpty) return;

    _isSyncing.value = true;
    debugPrint("--- Sync Starting: Found ${pendingRequests.length} pending items ---");

    for (var req in pendingRequests) {
      final id = req['id'];
      final endpoint = req['endpoint'];
      final method = req['method'];
      final headers = Map<String, String>.from(req['headers'] ?? {});
      final body = req['body'];

      try {
        late dynamic response;
        if (method == 'POST') {
          response = await ApiService.post(endpoint, headers: headers, body: body, bypassCache: true);
        } else if (method == 'PUT') {
          response = await ApiService.put(endpoint, headers: headers, body: body, bypassCache: true);
        } else if (method == 'DELETE') {
          response = await ApiService.delete(endpoint, headers: headers, bypassCache: true);
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint("Sync Success: $method $endpoint");
          await LocalCacheService.removePendingRequest(id);
        } else {
          debugPrint("Sync Failed: status code ${response.statusCode}");
          // Keep it to retry later or handle specific errors
        }
      } catch (e) {
        debugPrint("Sync Exception: $e");
        // Connection lost or API error, stop processing this queue for now
        break;
      }
    }

    _isSyncing.value = false;
    debugPrint("--- Sync Finished ---");
  }
}

