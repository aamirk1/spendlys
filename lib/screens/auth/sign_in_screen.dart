import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/screens/auth/components/my_text_field.dart';
import 'package:spendly/res/components/customBotton.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/colors.dart';

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final controller = Get.put(SignInController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'welcome_back'.tr,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'login_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 60),
                _buildFieldLabel(context, 'email_address'.tr),
                Obx(() => MyTextField(
                      controller: controller.emailController,
                      hintText: 'example@mail.com',
                      obscureText: false,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(CupertinoIcons.mail, size: 22),
                      errorMsg: controller.errorMsg.value,
                      validator: (val) {
                        if (val!.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(val)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel(context, 'password'.tr),
                    GestureDetector(
                      onTap: () => Get.toNamed(RoutesName.forgotPasswordView),
                      child: Text(
                        'forgot_password'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Obx(() => MyTextField(
                      controller: controller.passwordController,
                      hintText: 'Enter your password',
                      obscureText: controller.obscurePassword.value,
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: const Icon(CupertinoIcons.lock, size: 22),
                      errorMsg: controller.errorMsg.value,
                      validator: (val) {
                        if (val!.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        onPressed: controller.togglePasswordVisibility,
                        icon: Icon(
                          controller.obscurePassword.value
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    )),
                const SizedBox(height: 60),
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: CustomButton(
                        text: 'sign_in'.tr,
                        onPressed: controller.signIn,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        isLoading: controller.signInRequired.value,
                        borderRadius: 16,
                        fontSize: 18,
                        elevation: 0,
                      ),
                    )),
                // const SizedBox(height: 24),
                // Center(
                //   child: RichText(
                //     text: TextSpan(
                //       style: TextStyle(
                //           color: AppColors.textSecondary, fontSize: 14),
                //       children: [
                //         TextSpan(text: "dont_have_account".tr),
                //         WidgetSpan(
                //           child: GestureDetector(
                //             onTap: () => Get.toNamed(RoutesName.signupView),
                //             child: Text(
                //               ' ${'sign_up'.tr}',
                //               style: const TextStyle(
                //                 color: AppColors.primary,
                //                 fontWeight: FontWeight.bold,
                //               ),
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
      ),
    );
  }
}
