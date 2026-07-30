import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:spendly/utils/utils.dart';

class AppErrorHandler {
  static void handleError(dynamic error, {String? customTitle}) {
    String message = "Something went wrong. Please try again.";
    String title = customTitle ?? "Error";

    if (error is FirebaseException) {
      switch (error.code) {
        case 'user-not-found':
          message = "No account found with this email.";
          break;
        case 'wrong-password':
          message = "Invalid password. Please try again.";
          break;
        case 'invalid-email':
          message = "The email address is not valid.";
          break;
        case 'user-disabled':
          message = "This account has been disabled.";
          break;
        case 'email-already-in-use':
          message = "An account already exists with this email.";
          break;
        case 'weak-password':
          message = "The password is too weak.";
          break;
        case 'operation-not-allowed':
          message = "Operation not allowed. Please contact support.";
          break;
        case 'network-request-failed':
          message = "Network error. Please check your internet connection.";
          break;
        case 'too-many-requests':
        case 'too-many-attempts':
          message =
              "Too many failed attempts. Please wait a few minutes and try again.";
          break;
        case 'invalid-phone-number':
          message =
              "The phone number you entered is invalid. Please check and try again.";
          break;
        case 'missing-phone-number':
          message = "Please enter your phone number.";
          break;
        case 'quota-exceeded':
          message =
              "SMS quota for this project has been exceeded. Please try again later.";
          break;
        case 'captcha-check-failed':
          message =
              "App verification failed (reCAPTCHA check failed). Please ensure Google Play Services is enabled.";
          break;
        case 'app-not-authorized':
          message =
              "This app is not authorized to use Phone Authentication. Please check Firebase project settings.";
          break;
        case 'missing-client-identifier':
          message =
              "App verification failed. The app's signature/certificate hash is not registered in Firebase.";
          break;
        case 'session-expired':
          message =
              "The OTP verification session has expired. Please request a new OTP.";
          break;
        case 'invalid-verification-code':
          message =
              "The verification code you entered is incorrect. Please try again.";
          break;
        case 'invalid-verification-id':
          message =
              "Verification session is invalid. Please request a new OTP.";
          break;
        default:
          message = error.message ?? message;
      }

      // Format custom messages for specific obscure errors in firebase auth
      final lowercaseMsg = message.toLowerCase();
      if (lowercaseMsg.contains("17093") ||
          lowercaseMsg.contains("certificate hash") ||
          lowercaseMsg.contains("app verification") ||
          lowercaseMsg.contains("invalid_cert_hash")) {
        message =
            "App verification failed. The application certificate hash (SHA-1/SHA-256) is missing or mismatched in the Firebase Console. Please register your signature fingerprint.";
      } else if (lowercaseMsg.contains("too many attempts") ||
          lowercaseMsg.contains("too-many-attempts")) {
        message =
            "Too many attempts. The request was blocked to protect against spam. Please try again in a few minutes.";
      }
    } else if (error is DioException) {
      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        } else {
          message =
              "Server error: ${error.response?.statusCode}. Please try again later.";
        }
      } else {
        message = "Network error: ${error.message}";
      }
    } else if (error is Map && error.containsKey('detail')) {
      message = error['detail'].toString();
    } else if (error is Map && error.containsKey('message')) {
      message = error['message'].toString();
    } else if (error is SocketException) {
      message = "No internet connection. Please check your network.";
    } else if (error is TimeoutException) {
      message =
          "The request timed out. Please check your connection and try again.";
    } else if (error is FormatException) {
      message = "Bad data format from server.";
    } else {
      message = error.toString().replaceFirst("Exception: ", "");
    }

    Utils.showSnackbar(title, message, isError: true);
  }
}
