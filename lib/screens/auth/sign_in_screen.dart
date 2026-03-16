import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/screens/auth/components/my_text_field.dart';
import 'package:spendly/res/components/customBotton.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final controller = Get.put(SignInController());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to your account and stay on top of your finances.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 60),
                
                _buildFieldLabel('Email Address'),
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
                    _buildFieldLabel('Password'),
                    GestureDetector(
                      onTap: () => Get.toNamed(RoutesName.forgotPasswordView),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00B2E7),
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
                    text: 'Sign In',
                    onPressed: controller.signIn,
                    backgroundColor: const Color(0xFF00B2E7),
                    isLoading: controller.signInRequired.value,
                    borderRadius: 16,
                    fontSize: 18,
                    elevation: 0,
                  ),
                )),
                
                const SizedBox(height: 24),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Get.toNamed(RoutesName.signupView),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF00B2E7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }
}
