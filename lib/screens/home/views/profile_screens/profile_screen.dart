import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/common_bottom_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/links_card.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/user_info_section.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/profile_stats.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.myUser});
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('profile'.tr,
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Get.isDarkMode ? Colors.white : Colors.black87,
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 500),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              UserInfoSection(myUser: myUser),
              const ProfileStats(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Text(
                  'account'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Get.isDarkMode ? Colors.white38 : Colors.black38,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              LinksCard(myUser: myUser),
              const SizedBox(height: 24),
              CommonBottomScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
