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
import 'package:spendly/utils/utils.dart';
import 'package:pinput/pinput.dart';

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

  var resendAfter = 30.obs;
  var canResend = false.obs;
  Timer? _timer;

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

  void startResendTimer() {
    canResend.value = false;
    resendAfter.value = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendAfter.value > 0) {
        resendAfter.value--;
      } else {
        canResend.value = true;
        _timer?.cancel();
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
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
      Utils.showSnackbar('Error', 'Please fill all fields');
      return;
    }

    if (!isPhoneNumberValid(phoneNumberController.text.trim())) {
      Utils.showSnackbar('Error', 'Phone number must be 10 digits.');
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
        startResendTimer();
        _showOtpDialog(emailController.text.trim());
      } else {
        throw Exception(
            response.data['detail'] ?? 'Registration request failed');
      }
    } catch (e) {
      signUpRequired.value = false;
      debugPrint('Signup Error: $e');
      Utils.showSnackbar('Error', 'Failed to start registration: $e');
    }
  }

  Future<void> resendOtp() async {
    signUpRequired.value = true;
    try {
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
        startResendTimer();
        Utils.showSnackbar('Success', 'OTP resent successfully',
            isError: false);
      } else {
        throw Exception(response.data['detail'] ?? 'Resend OTP failed');
      }
    } catch (e) {
      signUpRequired.value = false;
      Utils.showSnackbar('Error', 'Failed to resend OTP: $e');
    }
  }

  void _showOtpDialog(String email) {
    final otpController = TextEditingController();

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF00B2E7), width: 2),
        color: Colors.white,
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFF00B2E7).withOpacity(0.05),
        border: Border.all(color: const Color(0xFF00B2E7).withOpacity(0.2)),
      ),
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B2E7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  size: 40,
                  color: Color(0xFF00B2E7),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                          text: 'Please enter the 6-digit code sent to\n'),
                      TextSpan(
                        text: email,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Pinput(
                length: 6,
                controller: otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                autofocus: true,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onCompleted: (pin) {
                  verifyOtp(email, pin);
                },
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      width: 22,
                      height: 1,
                      color: const Color(0xFF00B2E7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        canResend.value
                            ? "Didn't receive the code? "
                            : "Resend code in ",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (!canResend.value)
                        Text(
                          "${resendAfter.value}s",
                          style: const TextStyle(
                            color: Color(0xFF00B2E7),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      if (canResend.value)
                        GestureDetector(
                          onTap: () {
                            resendOtp();
                          },
                          child: const Text(
                            "Resend",
                            style: TextStyle(
                              color: Color(0xFF00B2E7),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  )),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: signUpRequired.value
                          ? null
                          : () {
                              if (otpController.text.length == 6) {
                                verifyOtp(email, otpController.text);
                              } else {
                                Utils.showSnackbar(
                                    'Error', 'Please enter a 6-digit OTP');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B2E7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: signUpRequired.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify & Proceed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  )),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Change Email',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
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
        final myUser = await _completeFirebaseRegistration(
            email, passwordController.text.trim());

        Get.back(); // Close dialog
        Utils.showSnackbar('Success', 'Account verified successfully',
            isError: false);
        Get.offAllNamed(RoutesName.onboardingView, arguments: myUser);
      } else {
        throw Exception(response.data['detail'] ?? 'OTP verification failed');
      }
    } catch (e) {
      signUpRequired.value = false;
      Utils.showSnackbar('Error', 'Verification failed: $e');
    }
  }

  Future<MyUser?> _completeFirebaseRegistration(
      String email, String password) async {
    MyUser? myUser;
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        myUser = MyUser.empty.copyWith(
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
        box.write("name", myUser.name); // Also save name

        // Sync with backend API to ensure user exists there with correct Firebase UID
        try {
          await _apiClient.post(
            ApiConstants.syncUser,
            data: {
              'id': user.uid,
              'email': email,
              'name': nameController.text.trim(),
              'phone_number': phoneNumberController.text.trim(),
              'device_info': deviceInfo,
              'fcm_token': fcmToken,
            },
          );
          debugPrint("Backend sync successful for ${user.uid}");
        } catch (apiError) {
          debugPrint("Backend sync failed: $apiError");
          // We don't throw here to avoid blocking the user if Firebase succeeded,
          // but this sync is important for Business Profile.
        }

        // Save credentials securely for future API calls
        await _secureStorage.saveCredentials(email, password);
      }
    } catch (e) {
      print("Firebase shadow registration failed: $e");
      // Not failing the whole process as backend registration is the source of truth now
    }
    signUpRequired.value = false;
    return myUser;
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
      Utils.showSnackbar('Error', 'Failed to save user data: ${e.message}');
    } on SocketException {
      Utils.showSnackbar('Network Error', 'No internet connection.');
    } on TimeoutException {
      Utils.showSnackbar('Timeout', 'Database request timed out.');
    } catch (e) {
      Utils.showSnackbar(
          'Error', 'Unexpected error while saving user data: $e');
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
