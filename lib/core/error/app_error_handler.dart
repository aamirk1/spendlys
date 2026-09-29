import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';
import 'package:spendly/utils/utils.dart';

class AppErrorHandler {
  /// Converts any technical or raw error into a user-friendly, understandable message.
  static String getErrorMessage(dynamic error) {
    if (error == null) return "Something went wrong. Please try again.";

    // 1. Timeout Exceptions
    if (error is TimeoutException) {
      return "The request timed out. Please check your internet connection and try again.";
    }

    // 2. Network Socket / Connectivity Exceptions
    if (error is SocketException) {
      return "No internet connection detected. Please verify your connection and try again.";
    }

    if (error is HttpException) {
      return "Unable to connect to the network. Please check your internet connection.";
    }

    // 3. Firebase Exceptions
    if (error is FirebaseException) {
      return _parseFirebaseError(error);
    }

    // 4. Dio (HTTP API) Exceptions
    if (error is DioException) {
      return _parseDioError(error);
    }

    // 5. Data formatting errors
    if (error is FormatException) {
      return "Unable to process the server response. Please try again later.";
    }

    // 6. Map responses (e.g. from backend API error payloads)
    if (error is Map) {
      if (error.containsKey('detail')) {
        return _formatServerDetail(error['detail']);
      }
      if (error.containsKey('message')) {
        return _formatServerDetail(error['message']);
      }
    }

    // 7. Generic / String exceptions
    String rawMsg = error.toString();
    if (rawMsg.startsWith("Exception: ")) {
      rawMsg = rawMsg.substring(11).trim();
    }

    return _sanitizeGenericMessage(rawMsg);
  }

  /// Displays a user-friendly error message via snackbar
  static void handleError(dynamic error, {String? customTitle}) {
    debugPrint("AppErrorHandler caught: $error");
    String title = customTitle ?? "Error";
    String message = getErrorMessage(error);
    Utils.showSnackbar(title, message, isError: true);
  }

  static String _parseFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'user-not-found':
        return "No account found with this email. Please check your email or create an account.";
      case 'wrong-password':
        return "Incorrect password. Please try again or tap 'Forgot?' to reset.";
      case 'invalid-credential':
        return "Invalid email or password. Please verify your details and try again.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'user-disabled':
        return "This account has been disabled. Please contact customer support.";
      case 'email-already-in-use':
        return "An account with this email already exists. Please sign in instead.";
      case 'weak-password':
        return "The password is too weak. Please use at least 6 characters.";
      case 'operation-not-allowed':
        return "This sign-in method is temporarily unavailable. Please try another method.";
      case 'network-request-failed':
        return "Network connection error. Please check your internet connection and try again.";
      case 'too-many-requests':
      case 'too-many-attempts':
        return "Too many failed attempts. For your security, please wait a few minutes and try again.";
      case 'invalid-phone-number':
        return "The phone number entered is invalid. Please check and try again.";
      case 'missing-phone-number':
        return "Please enter your mobile phone number.";
      case 'quota-exceeded':
        return "SMS limit reached for now. Please wait a short while before requesting another OTP.";
      case 'captcha-check-failed':
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return "Unable to verify your device or application. Please check your internet connection or try again later.";
      case 'session-expired':
        return "Your verification session has expired. Please request a new OTP.";
      case 'invalid-verification-code':
        return "The verification code you entered is incorrect. Please try again.";
      case 'invalid-verification-id':
        return "Verification session is no longer valid. Please request a new OTP.";
      case 'credential-already-in-use':
        return "This phone number is already linked to another account.";
      case 'requires-recent-login':
        return "For your security, please sign in again to continue.";
      case 'billing-not-enabled':
        return "Authentication service is temporarily unavailable. Please try again later.";
      case 'channel-error':
        return "Please ensure all fields are filled out correctly.";
      default:
        break;
    }

    final String raw = error.message ?? "";
    final String lower = raw.toLowerCase();

    if (lower.contains("17093") ||
        lower.contains("certificate hash") ||
        lower.contains("invalid_cert_hash") ||
        lower.contains("app verification") ||
        lower.contains("play services")) {
      return "Unable to verify your application. Please check your internet connection or update the app.";
    }

    if (lower.contains("too many attempts") ||
        lower.contains("too-many-attempts")) {
      return "Too many attempts. For your security, please wait a few minutes before trying again.";
    }

    if (lower.contains("network") ||
        lower.contains("timeout") ||
        lower.contains("connection")) {
      return "Network connection issue. Please check your internet connection.";
    }

    if (lower.contains("blocked all requests from this device")) {
      return "Too many requests from this device. Please wait a few minutes.";
    }

    return "Authentication failed. Please verify your details and try again.";
  }

  static String _parseDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Connection timed out. Please check your internet connection and try again.";
      case DioExceptionType.connectionError:
        return "Unable to connect to the server. Please check your internet connection.";
      case DioExceptionType.badCertificate:
        return "A secure connection could not be established. Please try again later.";
      case DioExceptionType.cancel:
        return "The request was cancelled.";
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data is Map) {
          if (data.containsKey('detail')) {
            return _formatServerDetail(data['detail'], statusCode: statusCode);
          }
          if (data.containsKey('message')) {
            return _formatServerDetail(data['message'], statusCode: statusCode);
          }
        }

        if (statusCode == 400) {
          return "Invalid request. Please check the details entered.";
        } else if (statusCode == 401) {
          return "Invalid email or password. Please verify your credentials.";
        } else if (statusCode == 403) {
          return "You do not have permission to perform this action.";
        } else if (statusCode == 404) {
          return "The requested account or resource could not be found.";
        } else if (statusCode == 409) {
          return "An account with these details already exists.";
        } else if (statusCode == 422) {
          return "Please check the information provided and try again.";
        } else if (statusCode == 429) {
          return "Too many requests. Please wait a moment and try again.";
        } else if (statusCode != null && statusCode >= 500) {
          return "Our server is temporarily unavailable. Please try again in a few moments.";
        }
        return "Something went wrong on the server. Please try again.";
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return "No internet connection detected. Please verify your connection.";
        }
        if (error.error is TimeoutException) {
          return "Connection timed out. Please check your internet connection.";
        }
        return "Unable to connect to the server. Please check your internet connection.";
    }
  }

  static String _formatServerDetail(dynamic detail, {int? statusCode}) {
    if (detail == null) return "An error occurred. Please try again.";

    // If detail is a list (e.g., FastAPI pydantic validation errors)
    if (detail is List) {
      if (detail.isNotEmpty && detail.first is Map) {
        final firstError = detail.first as Map;
        final msg = firstError['msg']?.toString();
        final loc = firstError['loc'];
        String field = '';
        if (loc is List && loc.isNotEmpty) {
          field = loc.last.toString().replaceAll('_', ' ');
        }
        if (msg != null) {
          if (field.isNotEmpty &&
              !msg.toLowerCase().contains(field.toLowerCase())) {
            return "Invalid $field: $msg.";
          }
          return msg;
        }
      }
      return "Please ensure all fields are filled in correctly.";
    }

    String text = detail.toString().trim();
    final lower = text.toLowerCase();

    if (lower.contains("invalid email or password") ||
        lower.contains("invalid credentials") ||
        lower.contains("incorrect email or password")) {
      return "Invalid email or password. Please try again.";
    }
    if (lower.contains("could not validate credentials") ||
        lower.contains("invalid token") ||
        lower.contains("token expired")) {
      return "Your session has expired. Please sign in again.";
    }
    if (lower.contains("user already exists") ||
        lower.contains("email already exists")) {
      return "An account with this email already exists.";
    }
    if (lower.contains("phone already exists") ||
        lower.contains("phone number already")) {
      return "An account with this phone number already exists.";
    }
    if (lower.contains("user not found")) {
      return "No account found with the provided details.";
    }
    if (lower.contains("incorrect password") ||
        lower.contains("invalid password") ||
        lower.contains("wrong password")) {
      return "Incorrect password. Please try again.";
    }
    if (lower.contains("old password") && lower.contains("match")) {
      return "Current password does not match. Please try again.";
    }
    if (lower.contains("invalid otp") || lower.contains("incorrect otp")) {
      return "The OTP code you entered is incorrect. Please try again.";
    }
    if (lower.contains("otp expired")) {
      return "The OTP code has expired. Please request a new OTP.";
    }
    if (lower.contains("internal server error") ||
        lower.contains("server error")) {
      return "Our server is temporarily unavailable. Please try again later.";
    }

    return _sanitizeGenericMessage(text);
  }

  static String _sanitizeGenericMessage(String raw) {
    if (raw.isEmpty) return "Something went wrong. Please try again.";

    final lower = raw.toLowerCase();

    // Check for technical stack trace, class names or internal errors
    if (lower.contains("formatexception") ||
        lower.contains("nosuchmethoderror") ||
        lower.contains("null check") ||
        lower.contains("nullpointer") ||
        lower.contains("typeerror") ||
        lower.contains("platformexception") ||
        lower.contains("sqflite") ||
        lower.contains("sql") ||
        lower.contains("stacktrace") ||
        lower.contains("xmlhttprequest")) {
      return "An unexpected error occurred. Please try again.";
    }

    if (lower.contains("failed host lookup") ||
        lower.contains("network is unreachable") ||
        lower.contains("connection refused") ||
        lower.contains("connection reset") ||
        lower.contains("software caused connection abort")) {
      return "Cannot connect to server. Please check your internet connection.";
    }

    if (lower.contains("timed out") || lower.contains("timeout")) {
      return "The request timed out. Please check your internet connection and try again.";
    }

    if (raw.length > 1) {
      raw = raw[0].toUpperCase() + raw.substring(1);
    }
    return raw;
  }
}
