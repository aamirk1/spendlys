import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/controllers/user_info_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/error/app_error_handler.dart';

class EditProfileController extends GetxController {
  final MyUser myUser;
  EditProfileController({required this.myUser});

  late TextEditingController nameController;
  late TextEditingController emailController;
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: myUser.name);
    emailController = TextEditingController(text: myUser.email);
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    final box = GetStorage();
    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();

    try {
      // 1. Sync with Backend API (Source of Truth)
      final apiClient = Get.find<ApiClient>();
      await apiClient.put(
        ApiConstants.profileUpdate,
        data: {
          "name": newName,
          "email": newEmail,
        },
      );

      // 2. Update Local Storage for immediate UI update
      box.write("name", newName);
      box.write("email", newEmail);

      // 3. Update Firestore (Legacy/Chat Support)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(myUser.userId)
            .update({
          'name': newName,
          'email': newEmail,
        }).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint("Firestore update failed (non-critical): $e");
      }

      Utils.showSnackbar("Success", "profile_updated_successfully".tr,
          isError: false);

      if (Get.isRegistered<UserInfoController>()) {
        Get.find<UserInfoController>().refreshUser();
      }

      // Small delay to allow UI to reflect non-loading state before popping
      await Future.delayed(const Duration(milliseconds: 300));
      Get.back(result: true);
    } catch (e) {
      debugPrint("Profile Update failed: $e");
      AppErrorHandler.handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
