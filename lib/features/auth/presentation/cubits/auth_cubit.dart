import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/di/service_locator.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthOtpSent extends AuthState {
  final String verificationId;
  const AuthOtpSent(this.verificationId);
  @override
  List<Object?> get props => [verificationId];
}
class AuthSuccess extends AuthState {
  final User user;
  final bool isNewUser;
  const AuthSuccess(this.user, this.isNewUser);
  @override
  List<Object?> get props => [user, isNewUser];
}
class AuthFailure extends AuthState {
  final String errorMessage;
  const AuthFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final GetStorage _box;
  final SecureStorageService _secureStorage = getIt<SecureStorageService>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  AuthCubit(this._authService, this._box) : super(AuthInitial());

  Future<void> sendOTP(String phone, {int? forceResendingToken}) async {
    emit(AuthLoading());

    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), "");
    if (!formattedPhone.startsWith("+")) {
      formattedPhone = "+91$formattedPhone";
    }

    try {
      await _authService.sendOTP(
        phoneNumber: formattedPhone,
        forceResendingToken: forceResendingToken,
        codeSent: (id, resendToken) {
          _box.write('verificationId', id);
          emit(AuthOtpSent(id));
        },
        verificationFailed: (e) {
          String errorMsg = e.message ?? "Verification failed";
          if (e.code == 'billing-not-enabled') {
            errorMsg = "Firebase billing not enabled. Please upgrade to Blaze plan.";
          }
          emit(AuthFailure(errorMsg));
        },
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            UserCredential userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            User? user = userCredential.user;
            if (user != null) {
              await syncUserWithBackend(user, "");
              _box.write("isLoggedIn", true);
              emit(AuthSuccess(user, userCredential.additionalUserInfo?.isNewUser ?? false));
            }
          } catch (e) {
            emit(AuthFailure(e.toString()));
          }
        },
      );
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> verifyOTP(String smsCode, {String? verificationId}) async {
    emit(AuthLoading());
    try {
      final vId = verificationId ?? _box.read('verificationId') ?? "";
      UserCredential userCredential = await _authService.verifyOTP(
        verificationId: vId,
        smsCode: smsCode,
      );

      User? user = userCredential.user;
      if (user != null) {
        _box.remove('verificationId');
        await syncUserWithBackend(user, "");
        _box.write("isLoggedIn", true);
        emit(AuthSuccess(user, userCredential.additionalUserInfo?.isNewUser ?? false));
      } else {
        emit(const AuthFailure("User not found after verification"));
      }
    } catch (e) {
      String msg = "Invalid OTP. Please try again.";
      if (e is FirebaseAuthException && e.message != null) {
        msg = e.message!;
      }
      emit(AuthFailure(msg));
    }
  }

  Future<void> syncUserWithBackend(User user, String name) async {
    try {
      String deviceInfo = await _getDeviceDetails();
      String? fcmToken = await _firebaseMessaging.getToken();

      String safePhone = (user.phoneNumber ?? "").replaceAll("+", "");
      if (safePhone.isEmpty) safePhone = user.uid.substring(0, 10);

      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post(
        ApiConstants.syncUser,
        data: {
          "id": user.uid,
          "phone_number": user.phoneNumber,
          "email": user.email ?? "$safePhone@dailybachat.com",
          "name": name.isNotEmpty ? name : (user.displayName ?? "User"),
          "password": "firebase_sync_placeholder",
          "device_info": deviceInfo,
          "fcm_token": fcmToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null) {
          final accessToken = data['access_token'];
          if (accessToken != null) {
            await _secureStorage.saveToken(accessToken);
          }
          final userData = data['user'];
          if (userData != null) {
            _box.write("userId", userData['id'] ?? '');
            _box.write("name", userData['name'] ?? '');
            _box.write("email", userData['email'] ?? '');
            _box.write("phoneNumber", userData['phone_number'] ?? '');
            _box.write("isPremium", userData['is_premium'] ?? false);
          }
        }
      }
    } catch (e) {
      debugPrint("Warning: Backend sync failed: $e");
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
}
