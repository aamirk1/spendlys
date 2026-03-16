class ApiConstants {
  static const String baseUrl =
      'https://dailybachatapi.serwex.in/api/v1'; // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator

  // Auth
  static const String login = '/auth/login';
  static const String registerRequest = '/auth/register/request';
  static const String registerVerify = '/auth/register/verify';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';
  static const String syncUser = '/auth/sync';


  // Transactions
  static const String transactions = '/transactions';

  // Loans
  static const String loans = '/loans';

  // Categories
  static const String categories = '/categories';

  // Stats
  static const String stats = '/stats';
}
