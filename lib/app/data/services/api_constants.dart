class ApiConstants {
  static const String baseUrl =
      'https://dailybachatapi.serwex.in/api/v1'; // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator

  // Trusted SSL Certificate SHA-256 Fingerprints for SSL Pinning
  static const List<String> allowedSSLPins = [
    '9AEF69BF7582A51A1EA957EFE7BD8CE496335A10C65EC1A9D43BAF1BB824BC6C',
    '97658DE8C68DFA98ACE1E5028A63D54A1AAE911B3E21471076C6850CD08CBAB4',
  ];

  // Auth
  static const String login = '/auth/login';
  static const String appConfig = '/auth/app-config';
  static const String registerRequest = '/auth/register/request';
  static const String registerVerify = '/auth/register/verify';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String syncUser = '/auth/sync';
  static const String profileUpdate = '/auth/me';
  static const String deleteRequest = '/auth/delete-request';
  static const String deleteAccount = '/auth/delete-account';
  static const String forgotPasswordRequest = '/auth/forgot-password/request';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';
  static const String changePassword = '/auth/change-password';

  // Transactions
  static const String transactions = '/transactions';

  // Loans
  static const String loans = '/loans';

  // Categories
  static const String categories = '/categories';

  // Stats
  static const String stats = '/stats';

  // Feedback
  static const String feedback = '/feedback';
}
