class ApiConstants {
  static const String baseUrl =
      'http://127.0.0.1:8000/api/v1'; // Update with your actual backend URL when hosting

  // Auth
  static const String login = '/auth/login';
  static const String registerRequest = '/auth/register/request';
  static const String registerVerify = '/auth/register/verify';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';

  // Transactions
  static const String transactions = '/transactions';

  // Loans
  static const String loans = '/loans';

  // Categories
  static const String categories = '/categories';

  // Stats
  static const String stats = '/stats';
}
