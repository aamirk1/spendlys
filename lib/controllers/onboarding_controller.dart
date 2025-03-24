import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';

class OnboardingController extends GetxController {
  var currentIndex = 0.obs;
  final PageController pageController = PageController();
  final box = GetStorage();

  void nextPage(MyUser myUser) {
    // Make myUser nullable
    if (currentIndex.value < 2) {
      pageController.nextPage(
          duration: Duration(milliseconds: 500), curve: Curves.ease);
    } else {
      box.write('hasSeenOnboarding', true); // Mark onboarding as seen
      Get.offAllNamed(RoutesName.homeView,
          arguments: myUser); // Modified: Passing MyUser instead of User
    }
  }
}
