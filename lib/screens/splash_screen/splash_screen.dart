import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:spendly/controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
   SplashScreen({super.key});

  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text('Splash Screen'),
        // Lottie.asset('assets/animations/splash_animation.json',
        //     width: 200, height: 500),
      ),
    );
  }
}
