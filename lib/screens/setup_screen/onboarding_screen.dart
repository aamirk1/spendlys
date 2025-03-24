import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:spendly/controllers/onboarding_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';

class OnboardingScreen extends StatelessWidget {
  final OnboardingController controller = Get.put(OnboardingController());
  final MyUser myUser = Get.arguments;
  final List<Map<String, String>> onboardingData = [
    {
      'animation': 'assets/animations/finance1.json',
      'title': 'Track Your Expenses',
      'description':
          'Keep an eye on your spending and manage your budget effectively.'
    },
    {
      'animation': 'assets/animations/finance2.json',
      'title': 'Set Budget Goals',
      'description': 'Plan and set limits to ensure you never overspend.'
    },
    {
      'animation': 'assets/animations/finance3.json',
      'title': 'Gain Financial Insights',
      'description':
          'Analyze your expenses and make smarter financial decisions.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(data['animation']!, height: 300),
                    SizedBox(height: 20),
                    Text(
                      data['title']!,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        data['description']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
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
    );
  }
}
