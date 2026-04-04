import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/utils/utils.dart';

class ForgotPasswordController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var isSending = false.obs;

  Future<void> sendPasswordResetEmail() async {
    if (emailController.text.isEmpty) {
      Utils.showSnackbar('Error', 'Please enter your email.');
      return;
    }

    isSending.value = true;

    try {
      await _auth
          .sendPasswordResetEmail(email: emailController.text.trim())
          .timeout(const Duration(seconds: 30));

      isSending.value = false;
      Utils.showSnackbar('Success', 'Password reset email sent.', isError: false);
      Get.back(); // go back to login screen
    } on FirebaseAuthException catch (e) {
      isSending.value = false;
      Utils.showSnackbar('Error', _getFirebaseAuthError(e.code));
    } on SocketException {
      isSending.value = false;
      Utils.showSnackbar('Network Error', 'No internet connection.');
    } on TimeoutException {
      isSending.value = false;
      Utils.showSnackbar('Timeout', 'Request timed out. Try again.');
    } catch (e) {
      isSending.value = false;
      Utils.showSnackbar('Error', 'Unexpected error: $e');
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
