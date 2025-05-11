import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';

class ChangePasswordController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> changePassword(MyUser myUser) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      User? user = FirebaseAuth.instance.currentUser;

      print(
          "Current user email: ${user?.email}, MyUser email: ${myUser.email}");

      if (user == null || user.email != myUser.email) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      await _firestore.collection('users').doc(user.uid).update({
        'lastPasswordChange': FieldValue.serverTimestamp(),
      });

      Get.back();
      Get.snackbar("Success", "Password changed successfully!",
          snackPosition: SnackPosition.BOTTOM);
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException caught: ${e.code} - ${e.message}");
      String errorMsg = _getFirebaseAuthError(e.code);
      Get.snackbar("Error", errorMsg, snackPosition: SnackPosition.BOTTOM);
    } on SocketException {
      Get.snackbar(
          "Network Error", "No internet connection. Please check your network.",
          snackPosition: SnackPosition.BOTTOM);
    } on TimeoutException {
      Get.snackbar("Timeout", "Request timed out. Try again later.",
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("Unexpected error: $e");
      Get.snackbar("Error", "Unexpected error: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  String _getFirebaseAuthError(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Your current password is incorrect.';
      case 'weak-password':
        return 'The new password is too weak.';
      case 'requires-recent-login':
        return 'Please sign in again and retry.';
      case 'user-not-found':
        return 'User not found. Please sign in again.';
      default:
        return 'Password change failed. Please try again.';
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
