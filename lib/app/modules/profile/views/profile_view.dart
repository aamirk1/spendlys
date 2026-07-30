import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/app/data/models/myuser.dart';
import 'package:spendly/app/modules/profile/widgets/common_bottom_screen.dart';
import 'package:spendly/app/modules/profile/widgets/links_card.dart';
import 'package:spendly/app/modules/profile/widgets/user_info_section.dart';
import 'package:spendly/app/modules/profile/widgets/profile_stats.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.myUser});
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('profile'.tr,
            style: const TextStyle(
                fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
          child: AnimationLimiter(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Text(
                  'account'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.5),
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
      )),
    );
  }
}
