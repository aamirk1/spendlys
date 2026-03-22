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
      child: Card(
        elevation: 0,
        color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _buildLinkItem(
              icon: Icons.person_outline_rounded,
              title: "customer_profile_update".tr,
              onPressed: () {},
            ),
            _buildDivider(),
            _buildLinkItem(
              icon: Icons.contact_emergency_outlined,
              title: "contact_details".tr,
              onPressed: () {},
            ),
            _buildDivider(),
            _buildLinkItem(
              icon: Icons.lock_outline_rounded,
              title: "change_password".tr,
              onPressed: () {
                Get.dialog(
                  ChangePasswordDialog(myUser: myUser),
                  barrierDismissible: false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.orange.shade800),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onPressed,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
    );
  }
}
