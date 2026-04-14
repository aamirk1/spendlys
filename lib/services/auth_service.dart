import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send OTP
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification on Android
        verificationCompleted(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP and Sign In
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-verification-id',
        message: 'Verification ID is missing. Please request a new OTP.',
      );
    }
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
