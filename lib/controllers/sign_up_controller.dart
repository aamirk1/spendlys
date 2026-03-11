import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';

class SignUpController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ApiClient _apiClient = Get.find<ApiClient>();
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();

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

  bool isPhoneNumberValid(String phoneNumber) {
    return phoneNumber.length == 10 &&
        RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber);
  }

  Future<void> signUp() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (!isPhoneNumberValid(phoneNumberController.text.trim())) {
      Get.snackbar('Error', 'Phone number must be 10 digits.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    signUpRequired.value = true;

    try {
      // Step 1: Request Registration & OTP from Backend
      final response = await _apiClient.post(
        ApiConstants.registerRequest,
        data: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneNumberController.text.trim(),
          'password': passwordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        signUpRequired.value = false;
        // Step 2: Show OTP Dialog
        _showOtpDialog(emailController.text.trim());
      } else {
        throw Exception(
            response.data['detail'] ?? 'Registration request failed');
      }
    } catch (e) {
      signUpRequired.value = false;
      Get.snackbar('Error', 'Failed to start registration: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showOtpDialog(String email) {
    final otpController = TextEditingController();
    Get.defaultDialog(
      title: 'Verify OTP',
      content: Column(
        children: [
          Text('Enter the 6-digit code sent to $email'),
          const SizedBox(height: 10),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: '123456',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: 'Verify',
      onConfirm: () {
        if (otpController.text.length == 6) {
          verifyOtp(email, otpController.text);
        } else {
          Get.snackbar('Error', 'Please enter a valid 6-digit OTP');
        }
      },
      barrierDismissible: false,
    );
  }

  Future<void> verifyOtp(String email, String otp) async {
    signUpRequired.value = true;
    try {
      final response = await _apiClient.post(
        ApiConstants.registerVerify,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        // Step 3: Registration Complete on Backend
        // For Chat, we still use Firebase, so let's also create the user in Firebase for Chat module
        await _completeFirebaseRegistration(
            email, passwordController.text.trim());

        Get.back(); // Close dialog
        Get.snackbar('Success', 'Account verified successfully',
            snackPosition: SnackPosition.BOTTOM);
        Get.offAllNamed(RoutesName.onboardingView);
      } else {
        throw Exception(response.data['detail'] ?? 'OTP verification failed');
      }
    } catch (e) {
      signUpRequired.value = false;
      Get.snackbar('Error', 'Verification failed: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _completeFirebaseRegistration(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        MyUser myUser = MyUser.empty.copyWith(
          userId: user.uid,
          phoneNumber: phoneNumberController.text.trim(),
          email: email,
          name: nameController.text.trim(),
        );

        String deviceInfo = await getDeviceInfo();
        String? fcmToken = await getFcmToken();
        await setUserData(myUser, deviceInfo, fcmToken);

        // Save locally
        final box = GetStorage();
        box.write("isLoggedIn", true);
        box.write("userId", myUser.userId);
        box.write("email", myUser.email);

        // Save credentials securely for future API calls
        await _secureStorage.saveCredentials(email, password);
      }
    } catch (e) {
      print("Firebase shadow registration failed: $e");
      // Not failing the whole process as backend registration is the source of truth now
    }
    signUpRequired.value = false;
  }

  Future<void> setUserData(
      MyUser myUser, String deviceInfo, String? fcmToken) async {
    try {
      await _firestore.collection('users').doc(myUser.userId).set({
        'userId': myUser.userId,
        'name': myUser.name,
        'email': myUser.email,
        'phoneNumber': myUser.phoneNumber,
        'deviceInfo': deviceInfo,
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      Get.snackbar('Error', 'Failed to save user data: ${e.message}',
          snackPosition: SnackPosition.BOTTOM);
    } on SocketException {
      Get.snackbar('Network Error', 'No internet connection.',
          snackPosition: SnackPosition.BOTTOM);
    } on TimeoutException {
      Get.snackbar('Timeout', 'Database request timed out.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Unexpected error while saving user data: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<String> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceData = 'Unknown Device';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceData =
          'Android - ${androidInfo.model} (SDK ${androidInfo.version.sdkInt})';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceData =
          'iOS - ${iosInfo.utsname.machine} (${iosInfo.systemVersion})';
    }
    return deviceData;
  }

  Future<String?> getFcmToken() async {
    final fcm = FirebaseMessaging.instance;
    return await fcm.getToken();
  }

  String _getFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'Email already exists.';
      case 'operation-not-allowed':
        return 'Sign-up currently disabled.';
      case 'user-creation-failed':
        return 'User creation failed.';
      case 'network-request-failed':
        return 'Network error.';
      default:
        return 'Sign-up failed. Try again.';
    }
  }
}