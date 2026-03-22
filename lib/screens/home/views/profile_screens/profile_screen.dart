import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/common_bottom_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/links_card.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/user_info_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.myUser});
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              UserInfoSection(myUser: myUser),
              LinksCard(myUser: myUser),
              CommonBottomScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
