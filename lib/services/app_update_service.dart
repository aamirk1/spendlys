import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkForUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      DocumentSnapshot config =
          await _firestore.collection('app_config').doc('update').get();

      if (config.exists) {
        Map<String, dynamic> data = config.data() as Map<String, dynamic>;
        String minVersion = data['min_version'] ?? '1.2.0';
        String storeUrl = data['store_url'] ?? '';

        if (_shouldUpdate(currentVersion, minVersion)) {
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
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> minParts = min.split('.').map(int.parse).toList();

    for (int i = 0; i < minParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (currentParts[i] < minParts[i]) return true;
      if (currentParts[i] > minParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(String storeUrl) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text('update_required'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('update_desc'.tr),
          actions: [
            TextButton(
              onPressed: () => _launchURL(storeUrl),
              child: Text('update_btn'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
