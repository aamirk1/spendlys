import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/change_password_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/custom_button.dart';

class ChangePasswordDialog extends StatelessWidget {
  ChangePasswordDialog({super.key, required this.myUser});

  final MyUser myUser;

  final controller = Get.put(ChangePasswordController());

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: Colors.purple, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Change Password",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 24),
                // Current Password Field
                Obx(() => TextFormField(
                      controller: controller.currentPasswordController,
                      obscureText: controller.obscureCurrentPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(controller.currentIcon.value),
                          onPressed: controller.toggleCurrentPasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 16),

                // New Password Field
                Obx(() => TextFormField(
                      controller: controller.newPasswordController,
                      obscureText: controller.obscureNewPassword.value,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(controller.newIcon.value),
                          onPressed: controller.toggleNewPasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 16),

                // Confirm Password Field
                Obx(() => TextFormField(
                      controller: controller.confirmPasswordController,
                      obscureText: controller.obscureConfirmPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        suffixIcon: IconButton(
                          icon: Icon(controller.confirmIcon.value),
                          onPressed: controller.toggleConfirmPasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != controller.newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 32),
                CustomButton(
                  onPressed: () async => await controller.changePassword(),
                  text: "Update Password",
                  backgroundColor: Colors.purple,
                  height: 54,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    if (Get.isDialogOpen == true) {
                      Get.back();
                    } else {
                      Navigator.of(context).pop();
                    }
                    Get.delete<ChangePasswordController>();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
