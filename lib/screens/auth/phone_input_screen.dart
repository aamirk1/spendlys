import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/auth_controller.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/res/components/shimmer_loading.dart';

class PhoneInputScreen extends StatelessWidget {
  PhoneInputScreen({super.key});

  final controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimationLimiter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 500),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  const Text(
                    "Welcome to DailyBachat",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login or Create a new account using your phone number",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text("Login"),
                            selected: !controller.isSignUp.value,
                            onSelected: (val) {
                              if (val) controller.toggleAuthMode();
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text("Signup"),
                            selected: controller.isSignUp.value,
                            onSelected: (val) {
                              if (val) controller.toggleAuthMode();
                            },
                          ),
                        ],
                      )),
                  const SizedBox(height: 32),
                  Obx(() {
                    return Column(
                      children: [
                        if (controller.isSignUp.value) ...[
                          TextField(
                            controller: controller.nameController,
                            decoration: InputDecoration(
                              labelText: "Full Name",
                              hintText: "Enter your name",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: controller.phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            hintText: "7558726131",
                            prefixText: "+91 ",
                            prefixStyle: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                        ),
                      ],
                    );
                  }),
                
                  const SizedBox(height: 32),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (controller.isLoading.value )
                              ? null
                              : () {
                                  if (controller
                                      .phoneController.text.isNotEmpty) {
                                    if (controller.isSignUp.value &&
                                        controller.nameController.text
                                            .trim()
                                            .isEmpty) {
                                      Get.snackbar(
                                          "Error", "Please enter your name",
                                          snackPosition: SnackPosition.BOTTOM);
                                      return;
                                    }
                                    controller.sendOTP(
                                        controller.phoneController.text);
                                  } else {
                                    Get.snackbar("Error",
                                        "Please enter a valid phone number",
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: controller.isLoading.value
                              ? const ButtonShimmer()
                              : Text(
                                  controller.isSignUp.value
                                      ? "Create Account"
                                      : "Login",
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
