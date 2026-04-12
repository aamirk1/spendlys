import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/core/error/app_error_handler.dart';

class ChangePasswordController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  var isLoading = false.obs;
  var obscureCurrentPassword = true.obs;
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;

  var currentIcon = CupertinoIcons.eye_fill.obs;
  var newIcon = CupertinoIcons.eye_fill.obs;
  var confirmIcon = CupertinoIcons.eye_fill.obs;

  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword.value = !obscureCurrentPassword.value;
    currentIcon.value = obscureCurrentPassword.value
        ? CupertinoIcons.eye_fill
        : CupertinoIcons.eye_slash_fill;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
    newIcon.value = obscureNewPassword.value
        ? CupertinoIcons.eye_fill
        : CupertinoIcons.eye_slash_fill;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
    confirmIcon.value = obscureConfirmPassword.value
        ? CupertinoIcons.eye_fill
        : CupertinoIcons.eye_slash_fill;
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final response = await _apiClient.post(
        ApiConstants.changePassword,
        data: {
          'old_password': currentPasswordController.text.trim(),
          'new_password': newPasswordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        Get.back();
        Utils.showSnackbar("Success", "Password changed successfully!", isError: false);
      } else {
        throw Exception(response.data['detail'] ?? 'Password change failed');
      }
    } catch (e) {
      AppErrorHandler.handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
