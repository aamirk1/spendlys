import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:spendly/utils/utils.dart';

class AppErrorHandler {
  static void handleError(dynamic error, {String? customTitle}) {
    String message = "Something went wrong. Please try again.";
    String title = customTitle ?? "Error";

    if (error is FirebaseAuthException) {
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
          message = "Network error. Please check your internet.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Try again later.";
          break;
        default:
          message = error.message ?? message;
      }
    } else if (error is DioException) {
      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (data is Map && data.containsKey('message')) {
          message = data['message'].toString();
        } else {
          message = "Server error: ${error.response?.statusCode}. Please try again later.";
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
      message = "The request timed out. Try again.";
    } else if (error is FormatException) {
      message = "Bad data format from server.";
    } else {
      message = error.toString().replaceFirst("Exception: ", "");
    }

    Utils.showSnackbar(title, message, isError: true);
  }
}
