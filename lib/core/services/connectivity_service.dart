import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:spendly/core/services/sync_service.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If ANY result is NOT .none, we consider the device online.
    bool online = !results.contains(ConnectivityResult.none);
    if (isOnline.value != online) {
      isOnline.value = online;
      if (online) {
        // Back online, trigger sync
        Get.find<SyncService>().startSync();
      }
    }
  }
}
