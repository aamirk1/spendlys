import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SignUpController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneNumberController = TextEditingController();

  var obscurePassword = true.obs;
  var signUpRequired = false.obs;

  var containsUpperCase = false.obs;
  var containsLowerCase = false.obs;
  var containsNumber = false.obs;
  var containsSpecialChar = false.obs;
  var contains8Length = false.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void checkPasswordStrength(String val) {
    containsUpperCase.value = val.contains(RegExp(r'[A-Z]'));
    containsLowerCase.value = val.contains(RegExp(r'[a-z]'));
    containsNumber.value = val.contains(RegExp(r'[0-9]'));
    containsSpecialChar.value =
        val.contains(RegExp(r'[!@#₹&*~`()%\-_+=;:,.<>?/"\[\]{}|^]'));
    contains8Length.value = val.length >= 8;
  }

  // Future<void> signUp() async {
  //   if (nameController.text.isEmpty ||
  //       emailController.text.isEmpty ||
  //       phoneNumberController.text.isEmpty ||
  //       passwordController.text.isEmpty) {
  //     Get.snackbar('Error', 'Please fill all fields',
  //         snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   }

  //   signUpRequired.value = true;

  //   try {
  //     UserCredential userCredential = await _auth
  //         .createUserWithEmailAndPassword(
  //           email: emailController.text.trim(),
  //           password: passwordController.text.trim(),
  //         )
  //         .timeout(const Duration(seconds: 10));

  //     User? user = userCredential.user;
  //     if (user == null) {
  //       throw FirebaseAuthException(code: "user-creation-failed");
  //     }

  //     MyUser myUser = MyUser.empty.copyWith(
  //       userId: user.uid,
  //       phoneNumber: phoneNumberController.text.trim(),
  //       email: emailController.text.trim(),
  //       name: nameController.text.trim(),
  //     );

  //     await setUserData(myUser);
  //     await addDefaultCategories(user.uid); // ✅ Add default categories

  //     signUpRequired.value = false;
  //     Get.snackbar('Success', 'Account created successfully',
  //         snackPosition: SnackPosition.BOTTOM);
  //     Get.offAllNamed(RoutesName.onboardingView, arguments: myUser);
  //   } on FirebaseAuthException catch (e) {
  //     signUpRequired.value = false;
  //     Get.snackbar('Error', _getFirebaseAuthError(e.code),
  //         snackPosition: SnackPosition.BOTTOM);
  //   } on FirebaseException catch (e) {
  //     signUpRequired.value = false;
  //     Get.snackbar('Error', 'Firestore error: ${e.message}',
  //         snackPosition: SnackPosition.BOTTOM);
  //   } on SocketException {
  //     signUpRequired.value = false;
  //     Get.snackbar(
  //         'Network Error', 'No internet connection. Please check your network.',
  //         snackPosition: SnackPosition.BOTTOM);
  //   } on TimeoutException {
  //     signUpRequired.value = false;
  //     Get.snackbar('Timeout', 'Network timeout. Please try again.',
  //         snackPosition: SnackPosition.BOTTOM);
  //   } catch (e) {
  //     signUpRequired.value = false;
  //     Get.snackbar('Error', 'Unexpected Error: $e',
  //         snackPosition: SnackPosition.BOTTOM);
  //   }
  // }
  Future<void> signUp() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    signUpRequired.value = true;

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 10));

      User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(code: "user-creation-failed");
      }

      MyUser myUser = MyUser.empty.copyWith(
        userId: user.uid,
        phoneNumber: phoneNumberController.text.trim(),
        email: emailController.text.trim(),
        name: nameController.text.trim(),
      );

      await setUserData(myUser);
      await addDefaultCategories(user.uid); // ✅ Add default categories

      // ✅ Save user details and login status in GetStorage
      final box = GetStorage();
      box.write("isLoggedIn", true);
      box.write("userId", myUser.userId);
      box.write("name", myUser.name);
      box.write("email", myUser.email);
      box.write("phoneNumber", myUser.phoneNumber);

      signUpRequired.value = false;
      Get.snackbar('Success', 'Account created successfully',
          snackPosition: SnackPosition.BOTTOM);
      Get.offAllNamed(RoutesName.onboardingView, arguments: myUser);
    } on FirebaseAuthException catch (e) {
      signUpRequired.value = false;
      Get.snackbar('Error', _getFirebaseAuthError(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } on FirebaseException catch (e) {
      signUpRequired.value = false;
      Get.snackbar('Error', 'Firestore error: ${e.message}',
          snackPosition: SnackPosition.BOTTOM);
    } on SocketException {
      signUpRequired.value = false;
      Get.snackbar(
          'Network Error', 'No internet connection. Please check your network.',
          snackPosition: SnackPosition.BOTTOM);
    } on TimeoutException {
      signUpRequired.value = false;
      Get.snackbar('Timeout', 'Network timeout. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      signUpRequired.value = false;
      Get.snackbar('Error', 'Unexpected Error: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> setUserData(MyUser myUser) async {
    try {
      await _firestore.collection('users').doc(myUser.userId).set({
        'userId': myUser.userId,
        'name': myUser.name,
        'email': myUser.email,
        'phoneNumber': myUser.phoneNumber,
      }).timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      Get.snackbar('Error', 'Failed to save user data: ${e.message}',
          snackPosition: SnackPosition.BOTTOM);
    } on SocketException {
      Get.snackbar(
          'Network Error', 'No internet connection. Please check your network.',
          snackPosition: SnackPosition.BOTTOM);
    } on TimeoutException {
      Get.snackbar('Timeout', 'Database request timed out. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Unexpected error while saving user data: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> addDefaultCategories(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // List of default categories with name, icon as IconData, and color as HEX
    final List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Food', 'icon': Icons.fastfood.codePoint, 'color': 'FFFFA500'},
      {
        'name': 'Transport',
        'icon': Icons.directions_car.codePoint,
        'color': 'FF0000FF'
      },
      {
        'name': 'Entertainment',
        'icon': Icons.movie.codePoint,
        'color': 'FF800080'
      },
      {
        'name': 'Shopping',
        'icon': Icons.local_mall.codePoint,
        'color': 'FF008000'
      },
      {
        'name': 'Health',
        'icon': Icons.medical_services.codePoint,
        'color': 'FFFF0000'
      },
      {
        'name': 'Education',
        'icon': Icons.school.codePoint,
        'color': 'FF008080'
      },
      {
        'name': 'Bills',
        'icon': Icons.account_balance_wallet.codePoint,
        'color': 'FF4B0082'
      },
      {
        'name': 'Other',
        'icon': Icons.more_horiz.codePoint,
        'color': 'FF808080'
      },
    ];

    for (var category in defaultCategories) {
      await firestore.collection('categories').add({
        'userId': userId,
        'name': category['name'],
        'icon': category['icon'], // Storing codePoint instead of asset path
        'color': category['color'], // Storing color as HEX string
      });
    }
  }

  /// **🔥 FIXED: Added missing _getFirebaseAuthError method**
  String _getFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak. Use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'operation-not-allowed':
        return 'Sign-up is currently disabled. Contact support.';
      case 'user-creation-failed':
        return 'Failed to create user. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Sign-up failed. Please try again.';
    }
  }
}
