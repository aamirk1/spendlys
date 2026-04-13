import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/core/error/app_error_handler.dart';

class ForgotPasswordController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  var isSending = false.obs;
  var isResetting = false.obs;
  var showOtpField = false.obs;

  Future<void> requestPasswordReset() async {
    if (phoneController.text.isEmpty) {
      Utils.showSnackbar('Error', 'Please enter your phone number.');
      return;
    }

    isSending.value = true;
    try {
      final response = await _apiClient.post(
        ApiConstants.forgotPasswordRequest,
        data: {'phone_number': phoneController.text.trim()},
      );

      if (response.statusCode == 200) {
        showOtpField.value = true;
        Utils.showSnackbar('Success', 'Reset OTP sent to your phone.', isError: false);
      } else {
        throw Exception(response.data['detail'] ?? 'Failed to request reset');
      }
    } catch (e) {
      AppErrorHandler.handleError(e);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (otpController.text.length != 6 || newPasswordController.text.length < 6) {
      Utils.showSnackbar('Error', 'Please enter a valid 6-digit OTP and a password (min 6 chars).');
      return;
    }

    isResetting.value = true;
    try {
      final response = await _apiClient.post(
        ApiConstants.forgotPasswordReset,
        data: {
          'phone_number': phoneController.text.trim(),
          'otp': otpController.text.trim(),
          'new_password': newPasswordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        Utils.showSnackbar('Success', 'Password reset successfully!', isError: false);
        Get.back(); // Return to Login
      } else {
        throw Exception(response.data['detail'] ?? 'Reset failed');
      }
    } catch (e) {
      AppErrorHandler.handleError(e);
    } finally {
      isResetting.value = false;
    }
  }
}
