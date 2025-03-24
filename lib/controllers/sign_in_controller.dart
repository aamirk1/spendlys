import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';

class SignInController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GetStorage box = GetStorage(); // 🔥 Initialize GetStorage
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

  // Add this method to your SignInController to convert User to MyUser
  Future<MyUser> _getUserData(String uid) async {
    // Fetch user data from Firestore
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    // Convert Firestore data to MyUser
    return MyUser(
      userId: userData['userId'] ?? uid,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
    );
  }

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields",
          snackPosition: SnackPosition.BOTTOM);
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
          .timeout(const Duration(seconds: 10));

      User? user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: "user-not-found");

      // Call the _getUserData method here
      MyUser myUser = await _getUserData(
          user.uid); // Now this works because _getUserData is defined

      // Save user details and login status in GetStorage
      box.write("isLoggedIn", true);
      box.write("userId", myUser.userId);
      box.write("name", myUser.name);
      box.write("email", myUser.email);
      box.write("phoneNumber", myUser.phoneNumber);

      signInRequired.value = false;
      Get.snackbar("Success", "Sign-in successful!",
          snackPosition: SnackPosition.BOTTOM);

      // Pass the MyUser object instead of the Firebase User
      Get.offAllNamed(RoutesName.homeView, arguments: myUser);
    } on FirebaseAuthException catch (e) {
      signInRequired.value = false;
      errorMsg.value = _getFirebaseAuthError(e.code);
      Get.snackbar("Error", errorMsg.value!,
          snackPosition: SnackPosition.BOTTOM);
    } on FirebaseException catch (e) {
      signInRequired.value = false;
      errorMsg.value = "Firestore error: ${e.message}";
      Get.snackbar("Error", errorMsg.value!,
          snackPosition: SnackPosition.BOTTOM);
    } on SocketException {
      signInRequired.value = false;
      errorMsg.value = "No internet connection. Please check your network.";
      Get.snackbar("Network Error", errorMsg.value!,
          snackPosition: SnackPosition.BOTTOM);
    } on TimeoutException {
      signInRequired.value = false;
      errorMsg.value = "Request timed out. Please try again later.";
      Get.snackbar("Timeout", errorMsg.value!,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      signInRequired.value = false;
      errorMsg.value = "Unexpected error: $e";
      Get.snackbar("Error", errorMsg.value!,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

//   Future<void> signIn() async {
//     if (emailController.text.isEmpty || passwordController.text.isEmpty) {
//       Get.snackbar("Error", "Please fill in all fields",
//           snackPosition: SnackPosition.BOTTOM);
//       return;
//     }

//     signInRequired.value = true;
//     errorMsg.value = null;

//     try {
//       UserCredential userCredential = await _auth
//           .signInWithEmailAndPassword(
//             email: emailController.text.trim(),
//             password: passwordController.text.trim(),
//           )
//           .timeout(const Duration(seconds: 10));

//       User? user = userCredential.user;
//       if (user == null) throw FirebaseAuthException(code: "user-not-found");

//       DocumentSnapshot userDoc = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .get()
//           .timeout(const Duration(seconds: 10));

//       if (!userDoc.exists) {
//         throw FirebaseAuthException(code: "user-data-not-found");
//       }

//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//       MyUser myUser = MyUser.empty.copyWith(
//         userId: userData['userId'] ?? user.uid,
//         name: userData['name'] ?? '',
//         email: userData['email'] ?? '',
//         phoneNumber: userData['phoneNumber'] ?? '',
//       );
// // Save user details in GetStorage
//       box.write("userId", myUser.userId);
//       box.write("name", myUser.name);
//       box.write("email", myUser.email);
//       box.write("phoneNumber", myUser.phoneNumber);
//       signInRequired.value = false;
//       Get.snackbar("Success", "Sign-in successful!",
//           snackPosition: SnackPosition.BOTTOM);

//       Get.offAllNamed(RoutesName.homeView, arguments: myUser);
//     } on FirebaseAuthException catch (e) {
//       signInRequired.value = false;
//       errorMsg.value = _getFirebaseAuthError(e.code);
//       Get.snackbar("Error", errorMsg.value!,
//           snackPosition: SnackPosition.BOTTOM);
//     } on FirebaseException catch (e) {
//       signInRequired.value = false;
//       errorMsg.value = "Firestore error: ${e.message}";
//       Get.snackbar("Error", errorMsg.value!,
//           snackPosition: SnackPosition.BOTTOM);
//     } on SocketException {
//       signInRequired.value = false;
//       errorMsg.value = "No internet connection. Please check your network.";
//       Get.snackbar("Network Error", errorMsg.value!,
//           snackPosition: SnackPosition.BOTTOM);
//     } on TimeoutException {
//       signInRequired.value = false;
//       errorMsg.value = "Request timed out. Please try again later.";
//       Get.snackbar("Timeout", errorMsg.value!,
//           snackPosition: SnackPosition.BOTTOM);
//     } catch (e) {
//       signInRequired.value = false;
//       errorMsg.value = "Unexpected error: $e";
//       Get.snackbar("Error", errorMsg.value!,
//           snackPosition: SnackPosition.BOTTOM);
//     }
//   }
  // Future<void> signIn() async {
  //   if (emailController.text.isEmpty || passwordController.text.isEmpty) {
  //     Get.snackbar("Error", "Please fill in all fields",
  //         snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   }

  //   signInRequired.value = true;
  //   errorMsg.value = null;

  //   try {
  //     UserCredential userCredential = await _auth
  //         .signInWithEmailAndPassword(
  //           email: emailController.text.trim(),
  //           password: passwordController.text.trim(),
  //         )
  //         .timeout(const Duration(seconds: 10));

  //     User? user = userCredential.user;
  //     if (user == null) throw FirebaseAuthException(code: "user-not-found");

  //     DocumentSnapshot userDoc = await _firestore
  //         .collection('users')
  //         .doc(user.uid)
  //         .get()
  //         .timeout(const Duration(seconds: 10));

  //     if (!userDoc.exists) {
  //       throw FirebaseAuthException(code: "user-data-not-found");
  //     }

  //     Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

  //     MyUser myUser = MyUser.empty.copyWith(
  //       userId: userData['userId'] ?? user.uid,
  //       name: userData['name'] ?? '',
  //       email: userData['email'] ?? '',
  //       phoneNumber: userData['phoneNumber'] ?? '',
  //     );

  //     // ✅ Save user details and login status in GetStorage
  //     box.write("isLoggedIn", true); // **New**
  //     box.write("userId", myUser.userId);
  //     box.write("name", myUser.name);
  //     box.write("email", myUser.email);
  //     box.write("phoneNumber", myUser.phoneNumber);

  //     signInRequired.value = false;
  //     Get.snackbar("Success", "Sign-in successful!",
  //         snackPosition: SnackPosition.BOTTOM);

  //     Get.offAllNamed(RoutesName.homeView, arguments: myUser);
  //   } on FirebaseAuthException catch (e) {
  //     signInRequired.value = false;
  //     errorMsg.value = _getFirebaseAuthError(e.code);
  //     Get.snackbar("Error", errorMsg.value!,
  //         snackPosition: SnackPosition.BOTTOM);
  //   } on FirebaseException catch (e) {
  //     signInRequired.value = false;
  //     errorMsg.value = "Firestore error: ${e.message}";
  //     Get.snackbar("Error", errorMsg.value!,
  //         snackPosition: SnackPosition.BOTTOM);
  //   } on SocketException {
  //     signInRequired.value = false;
  //     errorMsg.value = "No internet connection. Please check your network.";
  //     Get.snackbar("Network Error", errorMsg.value!,
  //         snackPosition: SnackPosition.BOTTOM);
  //   } on TimeoutException {
  //     signInRequired.value = false;
  //     errorMsg.value = "Request timed out. Please try again later.";
  //     Get.snackbar("Timeout", errorMsg.value!,
  //         snackPosition: SnackPosition.BOTTOM);
  //   } catch (e) {
  //     signInRequired.value = false;
  //     errorMsg.value = "Unexpected error: $e";
  //     Get.snackbar("Error", errorMsg.value!,
  //         snackPosition: SnackPosition.BOTTOM);
  //   }
  // }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    GetStorage().erase(); // ✅ Clear stored login data
    Get.offAllNamed(RoutesName.welcomeView);
  }

  String _getFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'User account has been disabled.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-data-not-found':
        return 'User data not found in Firestore.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
