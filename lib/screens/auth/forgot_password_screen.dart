import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/forgot_password_controller.dart';
import 'package:spendly/utils/colors.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final controller = Get.put(ForgotPasswordController());

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.tertiary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Text(
                        'reset_password'.tr,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'forgot_password_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Email TextField
                      TextField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'email_address'.tr,
                          hintText: 'example@gmail.com',
                          prefixIcon:
                              Icon(Icons.email, color: Colors.blue.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit Button
                      Obx(() => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: controller.isSending.value
                                ? 60
                                : double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: controller.isSending.value
                                  ? null
                                  : controller.sendPasswordResetEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: controller.isSending.value
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    )
                                  : Text(
                                      'send_reset_link'.tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
