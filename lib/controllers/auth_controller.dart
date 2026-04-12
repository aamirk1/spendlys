import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/services/auth_storage_service.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

import 'package:spendly/core/storage/secure_storage_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final AuthStorageService _storageService = Get.put(AuthStorageService());
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();
  final ApiClient _apiClient = Get.find<ApiClient>();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  var isLoading = false.obs;
  var isSignUp = false.obs;
  var verificationId = "".obs;
  var phoneNumber = "".obs;
  var name = "".obs;
  var isCaptchaVerified = false.obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void toggleAuthMode() {
    isSignUp.value = !isSignUp.value;
    clearFields();
  }

  void clearFields() {
    nameController.clear();
    phoneController.clear();
    isLoading.value = false;
    isCaptchaVerified.value = false;
    errorMsg.value = null;
  }

  var errorMsg = Rx<String?>(null);

  // Send OTP
  Future<void> sendOTP(String phone) async {
    isLoading.value = true;

    // Format phone number to E.164
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), "");
    if (!formattedPhone.startsWith("+")) {
      formattedPhone = "+91$formattedPhone"; // Defaulting to +91 for India
    }

    phoneNumber.value = formattedPhone;
    name.value = nameController.text.trim();

    try {
      await _authService.sendOTP(
        phoneNumber: formattedPhone,
        codeSent: (id) {
          verificationId.value = id;
          isLoading.value = false;
          Get.toNamed(RoutesName.otpVerifyView);
        },
        verificationFailed: (e) {
          isLoading.value = false;
          String errorMsg = e.message ?? "Verification failed";
          if (e.code == 'billing-not-enabled') {
            errorMsg =
                "Firebase billing not enabled. Please upgrade to Blaze plan.";
          }
          Fluttertoast.showToast(
            msg: errorMsg,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        },
      );
    } catch (e) {
      isLoading.value = false;
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  // Verify OTP
  Future<void> verifyOTP(String smsCode) async {
    isLoading.value = true;
    try {
      UserCredential userCredential = await _authService.verifyOTP(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Check if user is new from Firebase perspective
        bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          // It's a Signup flow - collect info first
          isLoading.value = false;
          // You can create a new route for this, for now we will sync with default and go to home
          // but in a real app, you'd go to RoutesName.completeProfile
          await syncUserWithBackend(user);
          await _storageService.saveUser(user.uid);
          Get.offAllNamed(RoutesName.homeView);
          Fluttertoast.showToast(msg: "Welcome! Account created successfully.");
        } else {
          // It's a Login flow
          await syncUserWithBackend(user);
          await _storageService.saveUser(user.uid);
          isLoading.value = false;
          Get.offAllNamed(RoutesName.homeView);
          Fluttertoast.showToast(msg: "Welcome back!");
        }
      }
    } catch (e) {
      isLoading.value = false;
      Fluttertoast.showToast(
        msg: "Invalid OTP. Please try again.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Sync with Backend (FastAPI)
  Future<void> syncUserWithBackend(User user) async {
    try {
      // Fetch Device Info & FCM Token
      String deviceInfo = await _getDeviceDetails();
      String? fcmToken = await _firebaseMessaging.getToken();

      final response = await _apiClient.post(
        ApiConstants.syncUser,
        data: {
          "id": user.uid,
          "phone_number": user.phoneNumber,
          "email": user.email ?? "${user.phoneNumber}@dailybachat.com",
          "name":
              name.value.isNotEmpty ? name.value : (user.displayName ?? "User"),
          "password": "firebase_phone_auth",
          "device_info": deviceInfo,
          "fcm_token": fcmToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final accessToken = data['access_token'];
        
        // Save the backend JWT token for future ApiClient calls
        if (accessToken != null) {
          await _secureStorage.saveToken(accessToken);
        }

        print("Backend sync successful: ${response.data}");
      }
    } catch (e) {
      print("Warning: Backend sync failed: $e");
    }
  }

  Future<String> _getDeviceDetails() async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      return 'Android ${androidInfo.version.release}, ${androidInfo.model}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
      return 'iOS ${iosInfo.systemVersion}, ${iosInfo.name}';
    } else {
      return 'Unknown Device';
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.signOut();
    await _storageService.clearUser();
    await _secureStorage.clearAll();
    Get.offAllNamed(RoutesName.loginView);
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
