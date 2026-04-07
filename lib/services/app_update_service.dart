import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';

class AppUpdateService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String defaultStoreUrl =
      "https://play.google.com/store/apps/details?id=com.technosolz.dailybachat";

  Future<bool> checkForUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      DocumentSnapshot config =
          await _firestore.collection('app_config').doc('update').get();

      if (config.exists) {
        Map<String, dynamic> data = config.data() as Map<String, dynamic>;
        String minVersion = data['min_version'] ?? '1.0.7';
        String storeUrl = data['store_url'] ?? defaultStoreUrl;
        bool forceUpdate = data['force_update'] ?? true;

        if (_shouldUpdate(currentVersion, minVersion) && forceUpdate) {
          _showUpdateDialog(storeUrl);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
    return false;
  }

  bool _shouldUpdate(String current, String min) {
    try {
      List<int> currentParts =
          current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> minParts =
          min.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < minParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (currentPart < minParts[i]) return true;
        if (currentPart > minParts[i]) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _showUpdateDialog(String storeUrl) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
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
                    Icons.update_rounded,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
      barrierDismissible: false,
    );
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
