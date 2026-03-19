import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/no_internet_screen.dart';

class NetworkChecker extends StatelessWidget {
  final Widget child;
  const NetworkChecker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Obx(() {
          final isOnline = Get.find<NetworkService>().isOnline.value;
          return isOnline ? const SizedBox.shrink() : const NoInternetScreen();
        }),
      ],
    );
  }
}
