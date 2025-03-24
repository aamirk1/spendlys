import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'components/my_text_field.dart';
import 'package:spendly/controllers/sign_up_controller.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final controller = Get.put(SignUpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: Obx(
          () => Column(
            children: [
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.90,
                child: MyTextField(
                  controller: controller.nameController,
                  hintText: 'Name',
                  obscureText: false,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(CupertinoIcons.person_fill),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.90,
                child: MyTextField(
                  prefixIcon: const Icon(CupertinoIcons.phone_fill),
                  controller: controller.phoneNumberController,
                  hintText: 'Mobile',
                  obscureText: false,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.90,
                child: MyTextField(
                  prefixIcon: const Icon(CupertinoIcons.mail_solid),
                  controller: controller.emailController,
                  hintText: 'Email',
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.90,
                child: MyTextField(
                  controller: controller.passwordController,
                  prefixIcon: const Icon(CupertinoIcons.lock_fill),
                  hintText: 'Password',
                  obscureText: controller.obscurePassword.value,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (val) {
                    controller.checkPasswordStrength(val!);
                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(controller.obscurePassword.value
                        ? CupertinoIcons.eye_fill
                        : CupertinoIcons.eye_slash_fill),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordRequirement(
                          '1 uppercase', controller.containsUpperCase.value),
                      _buildPasswordRequirement(
                          '1 lowercase', controller.containsLowerCase.value),
                      _buildPasswordRequirement(
                          '1 number', controller.containsNumber.value),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordRequirement('1 special character',
                          controller.containsSpecialChar.value),
                      _buildPasswordRequirement('8 characters minimum',
                          controller.contains8Length.value),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              controller.signUpRequired.value
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: TextButton(
                        onPressed: controller.signUp,
                        style: TextButton.styleFrom(
                          elevation: 3.0,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(60)),
                        ),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isValid) {
    return Text(
      '⚈  $text',
      style: TextStyle(color: isValid ? Colors.green : Colors.grey),
    );
  }
}
