import 'package:flutter/services.dart';

class Validators {
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? mobileValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final mobileRegex = RegExp(r'^\d{10}$');
    if (!mobileRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? ifscValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IFSC Code is required';
    }
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (value.length != 11) {
      return 'IFSC Code must be exactly 11 characters';
    }
    if (!ifscRegex.hasMatch(value.toUpperCase())) {
      return 'Enter a valid IFSC code (e.g., SBIN0001234)';
    }
    return null;
  }

  static String? accountNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account Number is required';
    }
    final accountRegex = RegExp(r'^\d{9,18}$');
    if (!accountRegex.hasMatch(value)) {
      return 'Enter a valid account number (9 to 18 digits)';
    }
    return null;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
