import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/controllers/localization_controller.dart';
import 'package:spendly/controllers/theme_controller.dart';
import 'package:spendly/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationController = Get.find<LocalizationController>();
    final themeController = Get.find<ThemeController>();
    final InAppReview inAppReview = InAppReview.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              _buildSectionHeader('general'.tr),
              _buildSettingCard(
                icon: Icons.language_rounded,
                title: 'language'.tr,
                subtitle: Obx(() {
                  final lang =
                      localizationController.currentLocale.value.split('_')[0];
                  String label = 'english'.tr;
                  if (lang == 'hi') label = 'hindi'.tr;
                  if (lang == 'mr') label = 'marathi'.tr;
                  if (lang == 'gu') label = 'gujarati'.tr;
                  return Text(label,
                      style: TextStyle(color: Colors.grey.shade500));
                }),
                onTap: () =>
                    _showLanguageDialog(context, localizationController),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('appearance'.tr),
              _buildSettingCard(
                icon: Icons.dark_mode_rounded,
                title: 'dark_mode'.tr,
                trailing: Obx(() => Switch(
                      value: themeController.isDarkMode,
                      onChanged: (val) => themeController.switchTheme(),
                      activeThumbColor: Theme.of(context).primaryColor,
                    )),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader('system_info'.tr),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  return _buildSettingCard(
                    icon: Icons.info_outline_rounded,
                    title: 'app_version'.tr,
                    subtitle: Text(
                      snapshot.hasData ? snapshot.data!.version : "...",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    onTap: () {
                      final updateService = Get.find<AppUpdateService>();
                      updateService.checkForUpdate();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, LocalizationController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'select_language'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _languageOption('english'.tr, 'en', 'US', controller),
            _languageOption('hindi'.tr, 'hi', 'IN', controller),
            _languageOption('marathi'.tr, 'mr', 'IN', controller),
            _languageOption('gujarati'.tr, 'gu', 'IN', controller),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String title, String langCode, String countryCode,
      LocalizationController controller) {
    final isSelected =
        controller.currentLocale.value == '${langCode}_$countryCode';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade700 : null)),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: Colors.blue.shade700)
            : null,
        onTap: () {
          controller.changeLanguage(langCode, countryCode);
          Get.back();
        },
      ),
    );
  }
}
