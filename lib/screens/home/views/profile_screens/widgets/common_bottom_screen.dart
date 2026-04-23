import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/home/views/profile_screens/feedback_screen.dart';
import 'package:in_app_review/in_app_review.dart';

class CommonBottomScreen extends StatelessWidget {
  CommonBottomScreen({super.key});
  final controller = Get.put(SignInController());
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> _requestReview() async {
    try {
      // For a manual "Rate Us" button click, openStoreListing is more reliable
      // because requestReview() is governed by strict OS quotas and may not show.
      if (await inAppReview.isAvailable()) {
        await inAppReview.openStoreListing(
            // appStoreId: '...', // Add iOS App Store ID here when available
            );
      } else {
        // Fallback: If for some reason the package can't open the store,
        // we can still provide a better experience or just log it.
        debugPrint("In-App Review: Store listing not available.");
      }
    } catch (e) {
      debugPrint("In-App Review Error: $e");
    }
  }

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
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.5),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.settings_outlined,
                  title: 'app_settings'.tr,
                  color: Colors.teal,
                  onTap: () => Get.toNamed(RoutesName.appSettingScreen),
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.help_outline_rounded,
                  title: 'need_help'.tr,
                  color: Colors.amber.shade700,
                  onTap: () => Get.toNamed(RoutesName.needHelpScreen),
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.feedback_outlined,
                  title: 'feedback'.tr,
                  color: Colors.green,
                  onTap: () => Get.to(() => const FeedbackScreen()),
                  context: context,
                ),
                _buildOptionItem(
                  icon: Icons.star_rate_rounded,
                  title: 'rate_us'.tr.isEmpty ? 'Rate Us' : 'rate_us'.tr,
                  color: Colors.orange,
                  onTap: _requestReview,
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.logout_rounded,
                  title: 'logout'.tr,
                  color: AppColors.red,
                  onTap: () => controller.logout(),
                  isDestructive: true,
                  context: context,
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
    required BuildContext context,
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
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Theme.of(context).disabledColor),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 20),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }
}
