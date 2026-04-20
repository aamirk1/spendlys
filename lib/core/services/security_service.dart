import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:safe_device/safe_device.dart';

class SecurityService extends GetxService {
  static SecurityService get to => Get.find();

  final RxBool isJailBroken = false.obs;
  final RxBool isDevelopmentMode = false.obs;
  final RxBool isSafe = true.obs;

  Future<SecurityService> init() async {
    await checkSecurity();
    return this;
  }

  Future<void> checkSecurity() async {
    try {
      // Check for Jailbreak / Root
      isJailBroken.value = await SafeDevice.isJailBroken;

      // Check for Development Mode / Developer Options
      // We only strictly block this in Release mode as requested
      isDevelopmentMode.value = await SafeDevice.isDevelopmentModeEnable;

      bool isRooted = isJailBroken.value;
      bool isDevOptionsOn = isDevelopmentMode.value && kReleaseMode;

      if (isRooted || isDevOptionsOn) {
        isSafe.value = false;
        _showSecurityWarning(isRooted, isDevOptionsOn);
      } else {
        isSafe.value = true;
      }
    } catch (e) {
      debugPrint("Security check error: $e");
    }
  }

  void _showSecurityWarning(bool rooted, bool devOptions) {
    String title = rooted ? "security_alert".tr : "dev_options_enabled".tr;
    String message = rooted ? "rooted_device_msg".tr : "dev_options_msg".tr;

    // Show a persistent dialog or navigate to a dedicated screen
    // Since this is initialized in main, we use Get.dialog with absolute persistence
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.red),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: Text("exit_app".tr,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
