import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/core/error/app_error_handler.dart';

class SignInController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  final GetStorage box = GetStorage();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var signInRequired = false.obs;
  var obscurePassword = true.obs;
  var iconPassword = CupertinoIcons.eye_fill.obs;
  var errorMsg = Rx<String?>(null);

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
    iconPassword.value = obscurePassword.value
        ? CupertinoIcons.eye_fill
        : CupertinoIcons.eye_slash_fill;
  }

  Future<MyUser> _getUserData(String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    return MyUser(
      userId: userData['userId'] ?? uid,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
      lastLogin: userData['lastLogin'] ?? Timestamp.now(),
    );
  }

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Utils.showSnackbar("Error", "Please fill in all fields");
      return;
    }

    signInRequired.value = true;
    errorMsg.value = null;

    try {
      UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 30));

      User? user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: "user-not-found");

      MyUser myUser = await _getUserData(user.uid);

      // Fetch Device Info
      String deviceInfo = await _getDeviceDetails();

      // Fetch FCM Token
      String? fcmToken = await _firebaseMessaging.getToken();

      // Update Firestore with device info and FCM token
      await _firestore.collection('users').doc(user.uid).update({
        'deviceInfo': deviceInfo,
        'fcmToken': fcmToken,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Save user details locally
      box.write("isLoggedIn", true);
      box.write("userId", myUser.userId);
      box.write("name", myUser.name);
      box.write("email", myUser.email);
      box.write("phoneNumber", myUser.phoneNumber);
      box.write("deviceInfo", deviceInfo);
      box.write("fcmToken", fcmToken);
      box.write("hasSeenOnboarding", true);

      signInRequired.value = false;
      Utils.showSnackbar("Success", "Sign-in successful!", isError: false);

      Get.offAllNamed(RoutesName.homeView, arguments: myUser);
    } catch (e) {
      signInRequired.value = false;
      AppErrorHandler.handleError(e);
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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    GetStorage().erase();
    Get.deleteAll(force: true); // Dispose all controllers
    Get.offAllNamed(RoutesName.loginView);
  }
}
