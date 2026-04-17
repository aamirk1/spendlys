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
      // Using PUT /auth/me instead of /auth/sync for clearer profile updates
      try {
        final apiClient = Get.find<ApiClient>();
        await apiClient.put(
          ApiConstants.profileUpdate,
          data: {
            "name": newName,
            "email": newEmail,
          },
        );
      } catch (e) {
        debugPrint("API Profile Update failed: $e");
        AppErrorHandler.handleError(e);
        isLoading.value = false;
        return; // Stop if API update fails as it's the source of truth
      }

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
        });
      } catch (e) {
        debugPrint("Firestore update failed: $e");
        // We continue because backend/local is updated
      }

      Utils.showSnackbar("Success", "profile_updated_successfully".tr,
          isError: false);

      if (Get.isRegistered<UserInfoController>()) {
        Get.find<UserInfoController>().refreshUser();
      }

      Get.back(result: true); // Return true to indicate update happened
    } catch (e) {
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
