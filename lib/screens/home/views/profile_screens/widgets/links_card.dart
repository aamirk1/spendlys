import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
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
            const SizedBox(height: 8),
            _buildLinkItem(
              icon: Icons.person_outline_rounded,
              title: "customer_profile_update".tr,
              color: Colors.blue,
              onPressed: () {},
            ),
            _buildDivider(),
            _buildLinkItem(
              icon: Icons.contact_emergency_outlined,
              title: "contact_details".tr,
              color: Colors.orange,
              onPressed: () {},
            ),
            _buildDivider(),
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
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
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
          child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade600),
        ),
        onTap: onPressed,
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
