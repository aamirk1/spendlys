import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/services/auth_service.dart';

class BusinessService extends GetxService {
  final RxBool isProfileCreated = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkProfileStatus();
  }

  Future<void> checkProfileStatus() async {
    final authService = Get.find<AuthService>();
    String? userId = authService.currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.get(
        '/business/profile',
        headers: {'x-user-id': userId},
        useCache: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // If the backend returns a valid profile with a name, we consider it created
        isProfileCreated.value = data != null && data['name'] != null && data['name'].toString().isNotEmpty;
        debugPrint("Business Profile Status Checked: ${isProfileCreated.value}");
      } else {
        isProfileCreated.value = false;
      }
    } catch (e) {
      debugPrint("Error checking business profile status: $e");
      isProfileCreated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void setProfileCreated(bool value) {
    isProfileCreated.value = value;
  }
}
