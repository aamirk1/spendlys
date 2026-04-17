import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';

class AppUpdateService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Default store URL for the app
  static const String defaultStoreUrl =
      "https://play.google.com/store/apps/details?id=com.technosolz.dailybachat";

  /// Checks Firestore for the minimum required version and shows a mandatory
  /// update dialog if the current version is too old.
  Future<bool> checkForUpdate() async {
    try {
      // 1. Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Fetch remote config from Firestore
      // Path: /app_config/update
      DocumentSnapshot config =
          await _firestore.collection('app_config').doc('update').get();

      if (config.exists) {
        Map<String, dynamic> data = config.data() as Map<String, dynamic>;
        
        // Example Firestore data:
        // { "min_version": "1.0.27", "store_url": "...", "force_update": true }
        String minVersion = data['min_version'] ?? '1.0.0';
        String storeUrl = data['store_url'] ?? defaultStoreUrl;
        bool forceUpdate = data['force_update'] ?? true;

        if (_shouldUpdate(currentVersion, minVersion)) {
          if (forceUpdate) {
            _showUpdateDialog(storeUrl);
            return true; // Update dialog is now blocking the UI
          }
        }
      }
    } catch (e) {
      debugPrint('AppUpdateService: Error during check: $e');
    }
    return false;
  }

  /// SemVer comparison logic (e.g., 1.0.25 vs 1.0.26)
  bool _shouldUpdate(String current, String minRequired) {
    try {
      List<int> currentParts =
          current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> minParts =
          minRequired.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Compare parts: major, minor, patch
      for (int i = 0; i < 3; i++) {
        int curr = i < currentParts.length ? currentParts[i] : 0;
        int min = i < minParts.length ? minParts[i] : 0;

        if (curr < min) return true;  // Current is older than minRequired
        if (curr > min) return false; // Current is newer than minRequired
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Displays a non-dismissible dialog that forces the user to the store.
  void _showUpdateDialog(String storeUrl) {
    Get.dialog(
      PopScope(
        canPop: false, // Prevents back button dismissal
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // You could show a toast here: "Update required to continue"
        },
        child: Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'update_required'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'update_desc'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _launchURL(storeUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'update_btn'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false, // Prevents clicking outside to dismiss
    );
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for some OS versions
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('AppUpdateService: Launch Error: $e');
    }
  }
}
