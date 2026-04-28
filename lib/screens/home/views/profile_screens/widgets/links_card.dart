import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/home/views/profile_screens/change_password_dialog.dart';

class LinksCard extends StatelessWidget {
  const LinksCard({super.key, required this.myUser});
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
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
            const SizedBox(height: 8),
            _buildLinkItem(
              icon: Icons.workspace_premium_rounded,
              title: "Upgrade to Premium",
              color: Colors.amber[800]!,
              onPressed: () {
                Get.toNamed(RoutesName.premiumView);
              },
              context: context,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'GO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.person_outline_rounded,
              title: "customer_profile_update".tr,
              color: Colors.blue,
              onPressed: () {
                Get.toNamed(RoutesName.editProfile, arguments: myUser);
              },
              context: context,
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.business_center_outlined,
              title: "business_profile".tr,
              color: Colors.indigo,
              onPressed: () {
                Get.toNamed(RoutesName.businessProfile);
              },
              context: context,
            ),
            _buildDivider(context),
            _buildLinkItem(
              icon: Icons.lock_outline_rounded,
              title: "change_password".tr,
              color: Colors.purple,
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
              color: Colors.red,
              onPressed: () {
                _showDeleteAccountDialog(context);
              },
              context: context,
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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                "delete_account".tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Are you sure you want to delete your account?",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                "This action is permanent and cannot be undone. All your transactions, categories, and profile data will be permanently removed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: () async {
                  Get.back(); // Close dialog
                  await controller.deleteAccountPermanently();
                },
                backgroundColor: Colors.red,
                text: "Delete Permanently",
                height: 54,
              ),
              const SizedBox(height: 8),
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: trailing ??
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Theme.of(context).disabledColor),
            ),
        onTap: onPressed,
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
