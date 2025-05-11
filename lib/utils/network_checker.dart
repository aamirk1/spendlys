import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/core/services/network_service.dart';
import 'package:spendly/no_internet_screen.dart';

class NetworkChecker extends StatelessWidget {
  final Widget child;
  const NetworkChecker({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOnline = Get.find<NetworkService>().isOnline.value;
      return isOnline ? child : const NoInternetScreen();
    });
  }
}
