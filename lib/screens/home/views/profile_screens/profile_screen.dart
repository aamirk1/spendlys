import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/common_bottom_screen.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/links_card.dart';
import 'package:spendly/screens/home/views/profile_screens/widgets/user_info_section.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key, required this.myUser});
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFFFF8D6C),
          automaticallyImplyLeading: true,
        ),
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UserInfoSection(
                  myUser: myUser,
                ),
                LinksCard(myUser: myUser),
                CommonBottomScreen()
              ],
            )
          ],
        ));
  }
}
