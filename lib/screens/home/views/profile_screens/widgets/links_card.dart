import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/home/views/profile_screens/change_password_dialog.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/referral_bottom_sheet.dart';

class LinksCard extends StatelessWidget {
  const LinksCard({super.key, required this.myUser});
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
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
            _buildLinkItem(
              icon: Icons.workspace_premium_rounded,
              title: "Upgrade to Premium",
              color: const Color(0xFFFFA500), // Classy Amber/Gold
              onPressed: () {
                Get.toNamed(RoutesName.premiumView);
              },
              context: context,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'UPGRADE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.person_outline_rounded,
              title: "customer_profile_update".tr,
              color: primaryColor,
              onPressed: () {
                Get.toNamed(RoutesName.editProfile, arguments: myUser);
              },
              context: context,
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.card_giftcard_rounded,
              title: "refer_earn".tr,
              color: primaryColor,
              onPressed: () {
                _showReferralBottomSheet(context);
              },
              context: context,
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.business_center_outlined,
              title: "business_profile".tr,
              color: primaryColor,
              onPressed: () {
                Get.toNamed(RoutesName.businessProfile);
              },
              context: context,
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.lock_outline_rounded,
              title: "change_password".tr,
              color: primaryColor,
              onPressed: () {
                Get.dialog(
                  ChangePasswordDialog(myUser: myUser),
                  barrierDismissible: false,
                );
              },
              context: context,
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.person_remove_outlined,
              title: "delete_account".tr,
              color: Colors.red.shade400,
              onPressed: () {
                _showDeleteAccountDialog(context);
              },
              context: context,
              isDestructive: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final controller = Get.find<SignInController>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_forever_rounded,
                    color: Colors.red.shade400, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                "delete_account".tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Are you sure you want to delete your account?",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "This action is permanent and cannot be undone. All your transactions, categories, and profile data will be permanently removed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: () async {
                  Get.back(); // Close dialog
                  await controller.deleteAccountPermanently();
                },
                backgroundColor: Colors.red.shade400,
                text: "Delete Permanently",
                height: 52,
                borderRadius: 14,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "cancel".tr,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
    required BuildContext context,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
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
              trailing ??
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

  void _showReferralBottomSheet(BuildContext context) {
    Get.bottomSheet(
      const ReferralBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }
}
