import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/app/data/models/myuser.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/data/services/api_client.dart';
import 'package:spendly/app/data/services/api_constants.dart';
import 'package:spendly/app/data/services/secure_storage_service.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:pinput/pinput.dart';
import 'package:spendly/app/data/services/app_error_handler.dart';

class SignUpController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _apiClient = Get.find<ApiClient>();
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();

  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final referredByController = TextEditingController();
  final formKey = GlobalKey<FormState>();

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
      String phoneNumberStr = phoneNumberController.text.trim();
      String formattedPhone = phoneNumberStr.replaceAll(RegExp(r'[^0-9+]'), "");
      if (!formattedPhone.startsWith("+")) {
        formattedPhone = "+91$formattedPhone"; // Defaulting to +91 for India
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            UserCredential userCredential =
                await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await syncSignUpWithBackend(userCredential.user!);
            }
          } catch (e) {
            signUpRequired.value = false;
            AppErrorHandler.handleError(e, customTitle: 'Verification Failed');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          signUpRequired.value = false;
          Utils.showSnackbar('Error', e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          signUpRequired.value = false;
          startResendTimer();
          _showMobileOtpDialog(formattedPhone, verificationId, Get.context!);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      signUpRequired.value = false;
      debugPrint('Signup Error: $e');
      AppErrorHandler.handleError(e, customTitle: 'Registration Failed');
    }
  }

  Future<void> resendOtp(String formattedPhone) async {
    signUpRequired.value = true;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            UserCredential userCredential =
                await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await syncSignUpWithBackend(userCredential.user!);
            }
          } catch (e) {
            signUpRequired.value = false;
            AppErrorHandler.handleError(e, customTitle: 'Verification Failed');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          signUpRequired.value = false;
          Utils.showSnackbar('Error', e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          signUpRequired.value = false;
          startResendTimer();
          Utils.showSnackbar('Success', 'OTP resent successfully',
              isError: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      signUpRequired.value = false;
      AppErrorHandler.handleError(e, customTitle: 'Resend Failed');
    }
  }

  void _showMobileOtpDialog(
      String formattedPhone, String verificationId, BuildContext context) {
    final otpController = TextEditingController();

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        color:
            Theme.of(Get.context!).textTheme.bodyLarge?.color ?? Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).dividerColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
            color: Theme.of(Get.context!).colorScheme.primary, width: 2),
        color: Theme.of(Get.context!).cardColor,
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color:
            Theme.of(Get.context!).colorScheme.primary.withValues(alpha: 0.05),
        border: Border.all(
            color: Theme.of(Get.context!)
                .colorScheme
                .primary
                .withValues(alpha: 0.2)),
      ),
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                  color: const Color(0xFF00B2E7).withValues(alpha: 0.1),
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
                        text: formattedPhone,
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
                  verifyMobileOtp(verificationId, pin);
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
                            resendOtp(formattedPhone);
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
                                verifyMobileOtp(
                                    verificationId, otpController.text);
                              } else {
                                Utils.showSnackbar(
                                    'Error', 'Please enter a 6-digit OTP');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                  'Change Number',
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

  Future<void> verifyMobileOtp(String verificationId, String smsCode) async {
    signUpRequired.value = true;
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await syncSignUpWithBackend(userCredential.user!);
      } else {
        throw Exception('Firebase authentication failed');
      }
    } catch (e) {
      signUpRequired.value = false;
      AppErrorHandler.handleError(e, customTitle: 'Verification Failed');
    }
  }

  Future<void> syncSignUpWithBackend(User firebaseUser) async {
    signUpRequired.value = true;
    try {
      String deviceInfo = await getDeviceInfo();
      String? fcmToken = await getFcmToken();

      final response = await _apiClient.post(
        ApiConstants.syncUser,
        data: {
          'id': firebaseUser.uid,
          'email': emailController.text.trim(),
          'name': nameController.text.trim(),
          'phone_number':
              firebaseUser.phoneNumber ?? phoneNumberController.text.trim(),
          'password': passwordController.text.trim(),
          'device_info': deviceInfo,
          'fcm_token': fcmToken,
          'referred_by_code': referredByController.text.trim().isEmpty
              ? null
              : referredByController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['user'];
        final accessToken = data['access_token'];

        // Save JWT for future API calls
        await _secureStorage.saveToken(accessToken);
        await _secureStorage.saveCredentials(
            emailController.text.trim(), passwordController.text.trim());

        MyUser myUser = MyUser(
          userId: userData['id'] ?? '',
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phoneNumber: userData['phone_number'] ?? '',
          lastLogin: Timestamp.now(),
          isPremium: userData['is_premium'] ?? false,
          referralCode: userData['referral_code'],
          referredById: userData['referred_by_id'],
          referralCount: userData['referral_count'] ?? 0,
        );

        // Sync to Firestore using WriteBatch (run in background)
        try {
          final batch = FirebaseFirestore.instance.batch();
          final userDocRef =
              FirebaseFirestore.instance.collection('users').doc(myUser.userId);
          batch.set(userDocRef, myUser.toMap(), SetOptions(merge: true));
          batch.commit().catchError((fe) {
            debugPrint("Firestore sync failed: $fe");
          });
        } catch (fe) {
          debugPrint("Firestore sync failed: $fe");
        }

        // Save locally
        final box = GetStorage();
        box.write("isLoggedIn", true);
        box.write("userId", myUser.userId);
        box.write("email", myUser.email);
        box.write("name", myUser.name);
        box.write("phoneNumber", myUser.phoneNumber);
        box.write('hasSeenOnboarding', true);
        box.write("isPremium", myUser.isPremium);
        box.write("referralCode", myUser.referralCode);
        box.write("referredById", myUser.referredById);
        box.write("referralCount", myUser.referralCount);

        Get.back(); // Close dialog
        Utils.showSnackbar('Success', 'Account verified successfully',
            isError: false);

        Get.offAllNamed(RoutesName.homeView, arguments: myUser);
      } else {
        throw Exception(response.data['detail'] ?? 'Sync failed');
      }
    } catch (e) {
      signUpRequired.value = false;
      AppErrorHandler.handleError(e, customTitle: 'Verification Failed');
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
}
