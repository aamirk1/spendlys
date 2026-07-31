import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:safe_device/safe_device.dart';

class SecurityService extends GetxService {
  static SecurityService get to => Get.find();

  final RxBool isJailBroken = false.obs;
  final RxBool isDevelopmentMode = false.obs;
  final RxBool isEmulator = false.obs;
  final RxBool isSafe = true.obs;

  Future<SecurityService> init() async {
    await checkSecurity();
    return this;
  }

  bool _hasRootBinaries() {
    if (kIsWeb || !Platform.isAndroid) return false;
    const rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
    ];
    for (final path in rootPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }
    return false;
  }

  Future<void> checkSecurity() async {
    try {
      // 1. Root / Jailbreak Detection
      final jailbroken = await SafeDevice.isJailBroken;
      final rootPathsFound = _hasRootBinaries();
      isJailBroken.value = jailbroken || rootPathsFound;

      // 2. Developer Options / USB Debugging Detection
      isDevelopmentMode.value = await SafeDevice.isDevelopmentModeEnable;

      // 3. Emulator / Virtual Device Detection
      final isReal = await SafeDevice.isRealDevice;
      isEmulator.value = !isReal;

      bool isRooted = isJailBroken.value;
      bool isDevOptionsOn = isDevelopmentMode.value && kReleaseMode;
      bool isRunningOnEmulator = isEmulator.value && kReleaseMode;

      if (isRooted || isDevOptionsOn || isRunningOnEmulator) {
        isSafe.value = false;
        _showSecurityWarning(
          rooted: isRooted,
          devOptions: isDevOptionsOn,
          emulator: isRunningOnEmulator,
        );
      } else {
        isSafe.value = true;
      }
    } catch (e) {
      debugPrint("Security check error: $e");
    }
  }

  void _showSecurityWarning({
    required bool rooted,
    required bool devOptions,
    required bool emulator,
  }) {
    String title = "security_alert".tr;
    String message = "rooted_device_msg".tr;

    if (rooted) {
      title = "security_alert".tr;
      message = "rooted_device_msg".tr;
    } else if (emulator) {
      title = "emulator_detected".tr;
      message = "emulator_msg".tr;
    } else if (devOptions) {
      title = "dev_options_enabled".tr;
      message = "dev_options_msg".tr;
    }

    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: Text("exit_app".tr, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
