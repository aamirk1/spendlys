import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  var isSending = false.obs;

  Future<void> sendPasswordResetEmail() async {
    if (emailController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter your email.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isSending.value = true;

    try {
      await _auth
          .sendPasswordResetEmail(email: emailController.text.trim())
          .timeout(const Duration(seconds: 30));

      isSending.value = false;
      Get.snackbar('Success', 'Password reset email sent.',
          snackPosition: SnackPosition.BOTTOM);
      Get.back(); // go back to login screen
    } on FirebaseAuthException catch (e) {
      isSending.value = false;
      Get.snackbar('Error', _getFirebaseAuthError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } on SocketException {
      isSending.value = false;
      Get.snackbar('Network Error', 'No internet connection.',
          snackPosition: SnackPosition.BOTTOM);
    } on TimeoutException {
      isSending.value = false;
      Get.snackbar('Timeout', 'Request timed out. Try again.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      isSending.value = false;
      Get.snackbar('Error', 'Unexpected error: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _getFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'network-request-failed':
        return 'Network error.';
      default:
        return 'Failed to send reset email.';
    }
  }
}
