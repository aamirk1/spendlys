import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/change_password_controller.dart';
import 'package:spendly/models/myuser.dart';

class ChangePasswordDialog extends StatelessWidget {
  ChangePasswordDialog({super.key, required this.myUser});

  final MyUser myUser;

  final controller = Get.put(ChangePasswordController());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change Password"),
      content: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Password Field
              Obx(() => TextFormField(
                    controller: controller.currentPasswordController,
                    obscureText: controller.obscureCurrentPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
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
              const SizedBox(height: 10),

              // New Password Field
              Obx(() => TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: controller.obscureNewPassword.value,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      suffixIcon: IconButton(
                        icon: Icon(controller.newIcon.value),
                        onPressed: controller.toggleNewPasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      return null;
                    },
                  )),
              const SizedBox(height: 10),

              // Confirm Password Field
              Obx(() => TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
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
            ],
          ),
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () {
            if (Get.isDialogOpen == true) {
              Get.back();
            } else {
              Navigator.of(context).pop();
            }
            Get.delete<ChangePasswordController>();
          },
          child: const Text("Cancel"),
        ),

        // Submit Button
        Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.changePassword(myUser),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Submit"),
            )),
      ],
    );
  }
}
