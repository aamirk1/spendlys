import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/user_info_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/utils/utils.dart';

class UserInfoSection extends StatelessWidget {
  UserInfoSection({super.key, required this.myUser});
  final MyUser myUser;

  final ImagePicker _picker = ImagePicker();
  final userInfoController = Get.put(UserInfoController());

  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      // Read the image as bytes
      List<int> imageBytes = await imageFile.readAsBytes();

      // Encode the image bytes to a Base64 string
      String base64Image = base64Encode(imageBytes);

      // Store the Base64 string in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUser.userId)
          .update({
        'profilePicture': base64Image,
      });

      // Instantly update the local state in the controller
      userInfoController.updateProfilePicture(base64Image);

      print("Profile Picture uploaded successfully.");
    } catch (e) {
      print("Error uploading profile picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = userInfoController.myUser.value;
      DateTime lastLoginDateTime = (user.lastLogin).toDate();
      String formattedDate =
          DateFormat('MMM dd, yyyy HH:mm').format(lastLoginDateTime);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        height: 250,
        child: Stack(
          children: [
            // Background Card with Gradient
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 45),
              padding: const EdgeInsets.fromLTRB(20, 65, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withBlue(220).withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // User name and status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTierBadge(user.isPremium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  // Bottom Info Badges (User ID and Last Active)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildInfoPill(
                          context,
                          '${'user_id'.tr}: ${user.userId.substring(user.userId.length - 5).toUpperCase()}',
                          Icons.vpn_key_outlined,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: user.userId));
                            Utils.showSnackbar(
                              'success'.tr,
                              'User ID copied to clipboard!',
                              isError: false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoPill(
                          context,
                          formattedDate,
                          Icons.history_toggle_off_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Floating Avatar centered
            Align(
              alignment: Alignment.topCenter,
              child: _buildModernAvatar(context, user.isPremium),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTierBadge(bool isPremium) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              )
            : null,
        color: isPremium ? null : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isPremium ? 'PRO' : 'FREE',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(BuildContext context, String text, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.copy_rounded, size: 10, color: Colors.white.withOpacity(0.6)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildModernAvatar(BuildContext context, bool isPremium) {
    return Obx(() {
      final user = userInfoController.myUser.value;
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                gradient: isPremium
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      )
                    : LinearGradient(
                        colors: [Colors.white, Colors.white.withOpacity(0.9)],
                      ),
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: user.image != null && user.image!.isNotEmpty
                      ? Image.memory(
                          base64Decode(user.image!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialsAvatar(context),
                        )
                      : _buildInitialsAvatar(context),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showPicker(context),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final user = userInfoController.myUser.value;
    return CircleAvatar(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'select_profile_pic'.tr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _pickerOption(
              context,
              Icons.camera_alt_rounded,
              'capture_camera'.tr,
              Colors.blue,
              () async {
                final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 50);
                if (image != null) await uploadProfilePicture(File(image.path));
                Get.back();
              },
            ),
            const SizedBox(height: 12),
            _pickerOption(
              context,
              Icons.photo_library_rounded,
              'select_gallery'.tr,
              Colors.purple,
              () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) await uploadProfilePicture(File(image.path));
                Get.back();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption(BuildContext context, IconData icon, String title,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
