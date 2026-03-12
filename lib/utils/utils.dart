import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Utils {
  static void showSnackbar(String title, String message, {bool isError = true}) {
    Get.rawSnackbar(
      title: title,
      message: message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.8),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }

  static void showToast(String message) {
    // Since fluttertoast is not installed, we'll use a simple snackbar as a 'toast' fallback
    // Or we can use Get.snackbar with shorter duration
    Get.rawSnackbar(
      message: message,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.7),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      borderRadius: 20,
    );
  }
}
