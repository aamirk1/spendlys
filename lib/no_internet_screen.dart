import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/custom_button.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  Future<void> _retryConnection() async {
    await Future.delayed(const Duration(seconds: 1));

    var result = await Connectivity().checkConnectivity();

    if (result.isNotEmpty && !result.contains(ConnectivityResult.none)) {
      // Internet واپس آیا — screen بند کریں
      Get.back();
    } else {
      Get.snackbar(
        'No Connection',
        'Still no internet. Please check your network.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 100,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 30),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your network settings and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                onPressed: _retryConnection,
                text: 'Retry',
                icon: const Icon(Icons.refresh, color: Colors.white),
                width: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
