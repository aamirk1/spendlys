import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/myuser.dart';
import 'dart:io';

// ignore: must_be_immutable
class UserInfoSection extends StatelessWidget {
  UserInfoSection({super.key, required this.myUser});
  final MyUser myUser;

  final ImagePicker _picker = ImagePicker();
  DateTime? newLastLogin;

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

      print("Profile Picture uploaded successfully.");
    } catch (e) {
      print("Error uploading profile picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime lastLoginDateTime = (myUser.lastLogin).toDate();
    String formattedDate =
        DateFormat('MMM dd yyyy HH:mm').format(lastLoginDateTime);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildModernAvatar(context),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myUser.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'user_id'.tr}: ${myUser.userId.substring(myUser.userId.length - 5).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  '${'last_login'.tr}: $formattedDate',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAvatar(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              myUser.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showPicker(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
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
              'select_profile_pic'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _pickerOption(
              Icons.camera_alt_rounded,
              'capture_camera'.tr,
              () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (image != null) await uploadProfilePicture(File(image.path));
                Get.back();
              },
            ),
            _pickerOption(
              Icons.photo_library_rounded,
              'select_gallery'.tr,
              () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) await uploadProfilePicture(File(image.path));
                Get.back();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
