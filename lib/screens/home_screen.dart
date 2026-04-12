import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/auth_controller.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome to DailyBachat!\nYou are successfully logged in.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
