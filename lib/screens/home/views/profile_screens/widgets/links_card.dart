import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/models/myuser.dart';
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
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "delete_account".tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "please_enter_reason_for_deletion".tr,
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "reason".tr,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("cancel".tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar("Error", "Please enter a reason");
                return;
              }
              Get.back(); // Close dialog
              controller.requestAccountDeletion(reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("submit".tr),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Theme.of(context).disabledColor),
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
