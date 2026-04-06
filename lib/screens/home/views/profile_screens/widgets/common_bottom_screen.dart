import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/res/routes/routes_name.dart';

class CommonBottomScreen extends StatelessWidget {
  CommonBottomScreen({super.key});
  final controller = Get.put(SignInController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Text(
              'more_options'.tr.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white38 : Colors.black38,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildOptionItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'notifications'.tr,
                  color: Colors.blue,
                  onTap: () => Get.toNamed(RoutesName.notificationsScreen),
                ),
                _buildDivider(),
                _buildOptionItem(
                  icon: Icons.settings_outlined,
                  title: 'app_settings'.tr,
                  color: Colors.teal,
                  onTap: () => Get.toNamed(RoutesName.appSettingScreen),
                ),
                _buildDivider(),
                _buildOptionItem(
                  icon: Icons.help_outline_rounded,
                  title: 'need_help'.tr,
                  color: Colors.amber.shade700,
                  onTap: () => Get.toNamed(RoutesName.needHelpScreen),
                ),
                _buildDivider(),
                _buildOptionItem(
                  icon: Icons.logout_rounded,
                  title: 'logout'.tr,
                  color: AppColors.red,
                  onTap: () => controller.logout(),
                  isDestructive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? AppColors.red : null,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 20),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.08)),
    );
  }
}
