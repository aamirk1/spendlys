import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/res/routes/routes_name.dart';

class CommonBottomScreen extends StatelessWidget {
  CommonBottomScreen({super.key});
  final controller = Get.put(SignInController());
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 5,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Get.toNamed(RoutesName.notificationsScreen);
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.notification_add,
                      size: 25,
                      color: AppColors.tertiary,
                    ),
                    Text(
                      'notifications'.tr,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Get.toNamed(RoutesName.appSettingScreen);
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.settings,
                      size: 25,
                      color: AppColors.tertiary,
                    ),
                    Text(
                      'app_settings'.tr,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Get.toNamed(RoutesName.needHelpScreen);
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.question_mark,
                      size: 25,
                      color: AppColors.tertiary,
                    ),
                    Text(
                      'need_help'.tr,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Center(
            child: InkWell(
              onTap: () {
                controller.logout();
              },
              child: Column(
                children: [
                  Icon(
                    Icons.logout,
                    size: 25,
                    color: AppColors.red,
                  ),
                  Text(
                    'logout'.tr,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            height: 15,
          )
        ],
      ),
    );
  }
}
