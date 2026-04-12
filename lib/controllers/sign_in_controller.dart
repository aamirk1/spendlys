import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/core/error/app_error_handler.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';

enum AuthMode { login, signup }

class SignInController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();
  final AuthService _authService = Get.find<AuthService>();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  final GetStorage box = GetStorage();

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final nameController = TextEditingController(); // Added for Signup

  final formKey = GlobalKey<FormState>();

  // State
  var authMode = AuthMode.login.obs;
  var isLoading = false.obs;
  var isEmailLogin = true.obs;
  var signInRequired = false.obs; // Keeping as alias for now if used elsewhere
  var obscurePassword = true.obs;
  var errorMsg = Rx<String?>(null);

  // Phone Auth Variables
  var verificationId = "".obs;
  var phoneNumber = "".obs;

  // Password Strength (from SignUpController)
  var containsUpperCase = false.obs;
  var containsLowerCase = false.obs;
  var containsNumber = false.obs;
  var containsSpecialChar = false.obs;
  var contains8Length = false.obs;

  void toggleAuthMode() {
    authMode.value =
        authMode.value == AuthMode.login ? AuthMode.signup : AuthMode.login;
    clearFields();
  }

  void toggleLoginMethod() {
    isEmailLogin.value = !isEmailLogin.value;
    clearFields();
  }

  void clearFields() {
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    nameController.clear();
    isLoading.value = false;
    signInRequired.value = false;
    errorMsg.value = null;
    // Reset password strength badges
    containsUpperCase.value = false;
    containsLowerCase.value = false;
    containsNumber.value = false;
    containsSpecialChar.value = false;
    contains8Length.value = false;
  }

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

  Future<void> requestAccountDeletion(String reason) async {
    if (reason.isEmpty) {
      Utils.showSnackbar("Error", "Please provide a reason for deletion");
      return;
    }

    try {
      Utils.showLoadingDialog();
      final user = auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      await _apiClient.post(ApiConstants.deleteRequest, data: {
        'user_id': user.uid,
        'reason': reason,
      });

      Get.back(); // Close loading dialog
      Utils.showSnackbar(
          "Success", "Deletion request submitted. Admin will review it.",
          isError: false);
    } catch (e) {
      Get.back(); // Close loading dialog
      Utils.showSnackbar("Error", "Failed to submit request: $e");
    }
  }

  var isSigningUpFlow =
      false.obs; // To track if we are in signup or login flow for OTP

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Utils.showSnackbar("Error", "Please fill in all fields");
      return;
    }

    signInRequired.value = true;
    errorMsg.value = null;

    try {
      // Fetch Device Info & FCM Token
      String deviceInfo = await _getDeviceDetails();
      String? fcmToken = await _firebaseMessaging.getToken();

      final response = await _apiClient.post(ApiConstants.login, data: {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'device_info': deviceInfo,
        'fcm_token': fcmToken,
      });

      final data = response.data;
      final accessToken = data['access_token'];
      final customToken = data['firebase_custom_token'];
      final userData = data['user'];

      // Sign in to Firebase using Custom Token
      if (customToken != null) {
        await auth
            .signInWithCustomToken(customToken)
            .timeout(const Duration(seconds: 30));
      }

      await _finalizeLogin(userData, accessToken, deviceInfo, fcmToken);

      // Save credentials for auto-login
      await _secureStorage.saveCredentials(
          emailController.text.trim(), passwordController.text.trim());
    } catch (e) {
      AppErrorHandler.handleError(e);
    } finally {
      signInRequired.value = false;
    }
  }

  Future<void> handleSignUp() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Utils.showSnackbar("Error", "Please fill in all fields");
      return;
    }

    if (phoneController.text.trim().length != 10) {
      Utils.showSnackbar("Error", "Please enter a valid 10-digit phone number");
      return;
    }

    isSigningUpFlow.value = true;
    await sendOTP();
  }

  Future<void> sendOTP([String? phone]) async {
    if (phone != null) {
      phoneController.text = phone.replaceAll("+91", "");
    }

    if (phoneController.text.isEmpty) {
      Utils.showSnackbar("Error", "Please enter your phone number");
      return;
    }

    isLoading.value = true;
    signInRequired.value = true;
    String phoneNumberStr = phoneController.text.trim();

    // Format phone number to E.164
    String formattedPhone = phoneNumberStr.replaceAll(RegExp(r'[^0-9+]'), "");
    if (!formattedPhone.startsWith("+")) {
      formattedPhone = "+91$formattedPhone"; // Defaulting to +91 for India
    }
    phoneNumber.value = formattedPhone;

    try {
      await _authService.sendOTP(
        phoneNumber: formattedPhone,
        codeSent: (id) {
          verificationId.value = id;
          isLoading.value = false;
          signInRequired.value = false;
          Get.toNamed(RoutesName.otpVerifyView,
              arguments: {'fromSignIn': true});
        },
        verificationFailed: (e) {
          isLoading.value = false;
          signInRequired.value = false;
          AppErrorHandler.handleError(e);
        },
      );
    } catch (e) {
      isLoading.value = false;
      signInRequired.value = false;
      AppErrorHandler.handleError(e);
    }
  }

  Future<void> verifyOTP(String smsCode) async {
    isLoading.value = true;
    try {
      UserCredential userCredential = await _authService.verifyOTP(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );

      User? user = userCredential.user;
      if (user != null) {
        if (isSigningUpFlow.value) {
          await syncSignUpWithBackend(user);
        } else {
          await syncUserByFirebaseToken(user);
        }
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Invalid OTP. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncSignUpWithBackend(User firebaseUser) async {
    try {
      String deviceInfo = await _getDeviceDetails();
      String? fcmToken = await _firebaseMessaging.getToken();

      final response = await _apiClient.post(ApiConstants.syncUser, data: {
        'id': firebaseUser.uid,
        'email': emailController.text.trim(),
        'name': nameController.text.trim(),
        'phone_number': firebaseUser.phoneNumber,
        'password': passwordController.text.trim(),
        'device_info': deviceInfo,
        'fcm_token': fcmToken,
      });

      await _finalizeLogin(response.data['user'], response.data['access_token'],
          deviceInfo, fcmToken);

      await _secureStorage.saveCredentials(
          emailController.text.trim(), passwordController.text.trim());
    } catch (e) {
      AppErrorHandler.handleError(e);
      rethrow;
    }
  }

  Future<void> syncUserByFirebaseToken(User firebaseUser) async {
    try {
      String deviceInfo = await _getDeviceDetails();
      String? fcmToken = await _firebaseMessaging.getToken();

      // Backend requires email and password in UserCreate schema used by /sync
      final response = await _apiClient.post(ApiConstants.syncUser, data: {
        'id': firebaseUser.uid,
        'email': firebaseUser.email ??
            (emailController.text.isNotEmpty
                ? emailController.text.trim()
                : "${firebaseUser.phoneNumber}@dailybachat.com"),
        'password': passwordController.text.isNotEmpty
            ? passwordController.text.trim()
            : "",
        'phone_number': firebaseUser.phoneNumber,
        'name': firebaseUser.displayName ??
            (nameController.text.isNotEmpty
                ? nameController.text.trim()
                : "User"),
        'device_info': deviceInfo,
        'fcm_token': fcmToken,
      });

      await _finalizeLogin(response.data['user'], response.data['access_token'],
          deviceInfo, fcmToken);
    } catch (e) {
      AppErrorHandler.handleError(e);
      rethrow;
    }
  }

  Future<void> _finalizeLogin(dynamic userData, String? accessToken,
      String deviceInfo, String? fcmToken) async {
    if (accessToken != null) {
      await _secureStorage.saveToken(accessToken);
    }

    MyUser myUser = MyUser(
      userId: userData['id'] ?? '',
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phone_number'] ?? '',
      lastLogin: Timestamp.now(),
      isPremium: userData['is_premium'] ?? false,
    );

    box.write("isLoggedIn", true);
    box.write("userId", myUser.userId);
    box.write("name", myUser.name);
    box.write("email", myUser.email);
    box.write("phoneNumber", myUser.phoneNumber);
    box.write("isPremium", myUser.isPremium);
    box.write("deviceInfo", deviceInfo);
    box.write("fcmToken", fcmToken);
    box.write("hasSeenOnboarding", true);

    signInRequired.value = false;
    Utils.showSnackbar("Success", "Authenticated successfully!",
        isError: false);
    Get.offAllNamed(RoutesName.homeView, arguments: myUser);
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

  Future<void> syncUserWithBackend(
      MyUser user, String deviceInfo, String? fcmToken) async {
    try {
      await _apiClient.post(ApiConstants.syncUser, data: {
        'id': user.userId,
        'email': user.email,
        'name': user.name,
        'phone_number': user.phoneNumber,
        'device_info': deviceInfo,
        'fcm_token': fcmToken,
      });
      print("User synced with backend successfully.");
    } catch (e) {
      print("Warning: Failed to sync user with backend: $e");
    }
  }

  Future<void> logout() async {
    await auth.signOut();
    await _secureStorage.clearAll();
    box.erase();
    Get.deleteAll(); // Dispose non-permanent controllers
    Get.offAllNamed(RoutesName.loginView);
  }
}
