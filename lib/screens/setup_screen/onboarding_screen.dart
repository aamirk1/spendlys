import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:spendly/controllers/onboarding_controller.dart';
import 'package:spendly/models/myuser.dart';

class OnboardingScreen extends StatelessWidget {
  final OnboardingController controller = Get.put(OnboardingController());
  final MyUser myUser = Get.arguments ?? MyUser.empty;

  final List<Map<String, String>> onboardingData = [
    {
      'animation': 'assets/animations/s_animation.json',
      'title': 'Track Your Expenses',
      'description':
          'Keep an eye on your spending and manage your budget effectively.'
    },
    {
      'animation': 'assets/animations/t_animation.json',
      'title': 'Set Budget Goals',
      'description': 'Plan and set limits to ensure you never overspend.'
    },
    {
      'animation': 'assets/animations/g_animation.json',
      'title': 'Gain Financial Insights',
      'description':
          'Analyze your expenses and make smarter financial decisions.'
    }
  ];

  OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  controller.currentIndex.value = index;
                },
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(data['animation']!, height: 300),
                        const SizedBox(height: 20),
                        Text(
                          data['title']!,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            data['description']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: controller.pageController,
              count: onboardingData.length,
              effect: ExpandingDotsEffect(activeDotColor: Colors.blueAccent),
            ),
            SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: () =>
                      controller.nextPage(myUser), // Remove the ! operator
                  child: Text(
                      controller.currentIndex.value == onboardingData.length - 1
                          ? 'Get Started'
                          : 'Next'),
                )),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
