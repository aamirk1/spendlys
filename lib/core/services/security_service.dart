import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:safe_device/safe_device.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SecurityService extends GetxService with WidgetsBindingObserver {
  static SecurityService get to => Get.find();

  final RxBool isJailBroken = false.obs;
  final RxBool isDevelopmentMode = false.obs;
  final RxBool isSafe = true.obs;
  final RxBool isSecurityDialogShowing = false.obs;

  Future<SecurityService> init() async {
    WidgetsBinding.instance.addObserver(this);
    // Initial silent check
    await _evaluateSecurityState();
    return this;
  }

  @override
  void onReady() {
    super.onReady();
    // Re-verify and display warning dialog once GetX/Navigator is mounted
    checkSecurity();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isSecurityDialogShowing.value) {
      _recheckOnResume();
    }
  }

  Future<void> _recheckOnResume() async {
    bool isDev = await SafeDevice.isDevelopmentModeEnable;
    isDevelopmentMode.value = isDev;

    // In release mode, check if dev mode was disabled
    if (!isDev) {
      debugPrint("SecurityService: Developer mode disabled by user.");
      isSecurityDialogShowing.value = false;
      isSafe.value = !isJailBroken.value;
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      // Reload current screen/splash if still on splash
      if (Get.currentRoute == RoutesName.splashScreen) {
        Get.offAllNamed(RoutesName.splashScreen);
      }
    } else {
      debugPrint("SecurityService: Developer mode is still active.");
    }
  }

  Future<void> _evaluateSecurityState() async {
    try {
      isJailBroken.value = await SafeDevice.isJailBroken;
      isDevelopmentMode.value = await SafeDevice.isDevelopmentModeEnable;

      bool isRooted = isJailBroken.value;
      bool isDevOptionsOn = isDevelopmentMode.value && kReleaseMode;

      if (isRooted || isDevOptionsOn) {
        isSafe.value = false;
      } else {
        isSafe.value = true;
      }
    } catch (e) {
      debugPrint("Security check error: $e");
    }
  }

  Future<bool> checkSecurity() async {
    await _evaluateSecurityState();

    bool isRooted = isJailBroken.value;
    bool isDevOptionsOn = isDevelopmentMode.value && kReleaseMode;

    if (isRooted || isDevOptionsOn) {
      if (!isSecurityDialogShowing.value) {
        _showSecurityWarning(isRooted, isDevOptionsOn);
      }
      return false;
    }
    return true;
  }

  static Future<void> openDeveloperSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        const platform = MethodChannel('com.spendly/security');
        final bool? res = await platform.invokeMethod('openDeveloperSettings');
        if (res == true) return;
      } catch (e) {
        debugPrint("Error opening developer settings via method channel: $e");
      }
    }
    // Fallback or iOS
    try {
      final uri = Uri.parse("app-settings:");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Error launching app-settings: $e");
    }
  }

  void _showSecurityWarning(bool rooted, bool devOptions) {
    if (isSecurityDialogShowing.value) return;
    isSecurityDialogShowing.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;

      if (devOptions) {
        // 2-button dialog for Developer Mode in release mode
        Get.dialog(
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              SystemNavigator.pop();
            },
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 12),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.developer_mode_rounded,
                      size: 40,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "dev_options_enabled".tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: Text(
                "dev_options_msg".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Button 1: Navigate to Developer Settings
                    ElevatedButton.icon(
                      onPressed: () => openDeveloperSettings(),
                      icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                      label: Text(
                        "settings".tr.isNotEmpty ? "settings".tr : "Open Settings",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Button 2: Exit App in Release Mode
                    OutlinedButton.icon(
                      onPressed: () => SystemNavigator.pop(),
                      icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                      label: Text(
                        "exit_app".tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      } else {
        // Rooted / Jailbroken device dialog
        Get.dialog(
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              SystemNavigator.pop();
            },
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.security, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  Text("security_alert".tr),
                ],
              ),
              content: Text("rooted_device_msg".tr),
              actions: [
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text(
                    "exit_app".tr,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      }
    });
  }
}

