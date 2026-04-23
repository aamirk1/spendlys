import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'components/my_text_field.dart';
import 'package:spendly/controllers/sign_up_controller.dart';
import 'package:spendly/utils/colors.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final controller = Get.put(SignUpController());

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
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'create_account'.tr,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join Spendly today and start tracking your expenses effortlessly.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFieldLabel(context, 'full_name'.tr),
                  MyTextField(
                    controller: controller.nameController,
                    hintText: 'John Doe',
                    obscureText: false,
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(CupertinoIcons.person, size: 22),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel(context, 'phone_number'.tr),
                  MyTextField(
                    prefixIcon: const Icon(CupertinoIcons.phone, size: 22),
                    controller: controller.phoneNumberController,
                    hintText: '10-digit mobile number',
                    obscureText: false,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val!.isEmpty) return 'Please enter your phone number';
                      if (val.length != 10) {
                        return 'Phone number must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel(context, 'email_address'.tr),
                  MyTextField(
                    prefixIcon: const Icon(CupertinoIcons.mail, size: 22),
                    controller: controller.emailController,
                    hintText: 'example@mail.com',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val!.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel(context, 'password'.tr),
                  MyTextField(
                    controller: controller.passwordController,
                    prefixIcon: const Icon(CupertinoIcons.lock, size: 22),
                    hintText: 'create a strong password',
                    obscureText: controller.obscurePassword.value,
                    keyboardType: TextInputType.visiblePassword,
                    validator: (val) {
                      if (val!.isEmpty) return 'Please create a password';
                      if (val.length < 8) return 'Password too short';
                      return null;
                    },
                    onChanged: (val) {
                      controller.checkPasswordStrength(val!);
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
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildPasswordRequirement('Uppercase',
                                    controller.containsUpperCase.value)),
                            Expanded(
                                child: _buildPasswordRequirement('Lowercase',
                                    controller.containsLowerCase.value)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildPasswordRequirement('1 Number',
                                    controller.containsNumber.value)),
                            Expanded(
                                child: _buildPasswordRequirement('Special Char',
                                    controller.containsSpecialChar.value)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildPasswordRequirement('8 characters minimum',
                            controller.contains8Length.value),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: CustomButton(
                      text: 'create_account'.tr,
                      onPressed: () async {
                        if (controller.formKey.currentState!.validate()) {
                          await controller.signUp();
                        }
                      },
                      backgroundColor: AppColors.primary,
                      isLoading: controller.signUpRequired.value,
                      borderRadius: 16,
                      fontSize: 18,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                            fontSize: 14),
                        children: [
                          TextSpan(text: 'already_have_account'.tr),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Get.back(),
                              child: Text(
                                ' ${'sign_in'.tr}',
                                style: const TextStyle(
                                  color: AppColors.primary,
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

  Widget _buildPasswordRequirement(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: isValid ? Colors.green : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isValid ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
