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
      if (await inAppReview.isAvailable()) {
        await inAppReview.openStoreListing();
      } else {
        debugPrint("In-App Review: Store listing not available.");
      }
    } catch (e) {
      debugPrint("In-App Review Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

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
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildOptionItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'notifications'.tr,
                  color: primaryColor,
                  onTap: () => Get.toNamed(RoutesName.notificationsScreen),
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.settings_outlined,
                  title: 'app_settings'.tr,
                  color: primaryColor,
                  onTap: () => Get.toNamed(RoutesName.appSettingScreen),
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.help_outline_rounded,
                  title: 'need_help'.tr,
                  color: primaryColor,
                  onTap: () => Get.toNamed(RoutesName.needHelpScreen),
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.feedback_outlined,
                  title: 'feedback'.tr,
                  color: primaryColor,
                  onTap: () => Get.to(() => const FeedbackScreen()),
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.star_rate_rounded,
                  title: 'rate_us'.tr.isEmpty ? 'Rate Us' : 'rate_us'.tr,
                  color: primaryColor,
                  onTap: _requestReview,
                  context: context,
                ),
                _buildDivider(context),
                _buildOptionItem(
                  icon: Icons.logout_rounded,
                  title: 'logout'.tr,
                  color: Colors.red.shade400,
                  onTap: () => controller.logout(),
                  isDestructive: true,
                  context: context,
                ),
                const SizedBox(height: 8),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDestructive ? Colors.red.shade400 : null,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Theme.of(context).disabledColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68, right: 20),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.06),
      ),
    );
  }
}
