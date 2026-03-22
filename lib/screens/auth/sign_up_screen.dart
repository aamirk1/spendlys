import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/customBotton.dart';
import 'components/my_text_field.dart';
import 'package:spendly/controllers/sign_up_controller.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final controller = Get.put(SignUpController());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

                Text(
                  'create_account'.tr,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Spendly today and start tracking your expenses effortlessly.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildFieldLabel('full_name'.tr),
                MyTextField(
                  controller: controller.nameController,
                  hintText: 'John Doe',
                  obscureText: false,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(CupertinoIcons.person, size: 22),
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('phone_number'.tr),
                MyTextField(
                  prefixIcon: const Icon(CupertinoIcons.phone, size: 22),
                  controller: controller.phoneNumberController,
                  hintText: '10-digit mobile number',
                  obscureText: false,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('email_address'.tr),
                MyTextField(
                  prefixIcon: const Icon(CupertinoIcons.mail, size: 22),
                  controller: controller.emailController,
                  hintText: 'example@mail.com',
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('password'.tr),
                MyTextField(
                  controller: controller.passwordController,
                  prefixIcon: const Icon(CupertinoIcons.lock, size: 22),
                  hintText: 'create a strong password',
                  obscureText: controller.obscurePassword.value,
                  keyboardType: TextInputType.visiblePassword,
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildPasswordRequirement('Uppercase', controller.containsUpperCase.value)),
                          Expanded(child: _buildPasswordRequirement('Lowercase', controller.containsLowerCase.value)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildPasswordRequirement('1 Number', controller.containsNumber.value)),
                          Expanded(child: _buildPasswordRequirement('Special Char', controller.containsSpecialChar.value)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordRequirement('8 characters minimum', controller.contains8Length.value),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: CustomButton(
                    text: 'create_account'.tr,
                    onPressed: controller.signUp,
                    backgroundColor: const Color(0xFF00B2E7),
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
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      children: [
                        TextSpan(text: 'already_have_account'.tr),
                        TextSpan(
                          text: 'sign_in'.tr,
                          style: const TextStyle(
                            color: Color(0xFF00B2E7),
                            fontWeight: FontWeight.bold,
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
