import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/di/service_locator.dart';

abstract class SignUpState extends Equatable {
  const SignUpState();
  @override
  List<Object?> get props => [];
}

class SignUpInitial extends SignUpState {}
class SignUpLoading extends SignUpState {}
class SignUpOtpSent extends SignUpState {
  final String email;
  const SignUpOtpSent(this.email);
  @override
  List<Object?> get props => [email];
}
class SignUpSuccess extends SignUpState {
  final MyUser user;
  const SignUpSuccess(this.user);
  @override
  List<Object?> get props => [user];
}
class SignUpFailure extends SignUpState {
  final String errorMessage;
  const SignUpFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class SignUpCubit extends Cubit<SignUpState> {
  final GetStorage _box;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecureStorageService _secureStorage = getIt<SecureStorageService>();

  SignUpCubit(this._box) : super(SignUpInitial());

  Future<void> signUp({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    emit(SignUpLoading());
    try {
      String deviceInfo = await getDeviceInfo();
      String? fcmToken = await getFcmToken();

      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post(
        ApiConstants.registerRequest,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'phone_number': phoneNumber.trim(),
          'password': password.trim(),
          'device_info': deviceInfo,
          'fcm_token': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        emit(SignUpOtpSent(email.trim()));
      } else {
        emit(SignUpFailure(response.data['detail'] ?? 'Registration request failed'));
      }
    } catch (e) {
      emit(SignUpFailure(e.toString()));
    }
  }

  Future<void> resendOtp({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    emit(SignUpLoading());
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post(
        ApiConstants.registerRequest,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'phone_number': phoneNumber.trim(),
          'password': password.trim(),
        },
      );

      if (response.statusCode == 200) {
        emit(SignUpOtpSent(email.trim()));
      } else {
        emit(SignUpFailure(response.data['detail'] ?? 'Resend OTP failed'));
      }
    } catch (e) {
      emit(SignUpFailure(e.toString()));
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    emit(SignUpLoading());
    try {
      String deviceInfo = await getDeviceInfo();
      String? fcmToken = await getFcmToken();

      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post(
        ApiConstants.registerVerify,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
          'device_info': deviceInfo,
          'fcm_token': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['user'];
        final accessToken = data['access_token'];
        final customToken = data['firebase_custom_token'];

        if (customToken != null) {
          try {
            await _auth.signInWithCustomToken(customToken);
          } catch (e) {
            debugPrint("Firebase background auth failed: $e");
          }
        }

        await _secureStorage.saveToken(accessToken);
        await _secureStorage.saveCredentials(email.trim(), password.trim());

        MyUser myUser = MyUser(
          userId: userData['id'] ?? '',
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phoneNumber: userData['phone_number'] ?? '',
          lastLogin: Timestamp.now(),
        );

        _box.write("isLoggedIn", true);
        _box.write("userId", myUser.userId);
        _box.write("email", myUser.email);
        _box.write("name", myUser.name);
        _box.write("phoneNumber", myUser.phoneNumber);
        _box.write('hasSeenOnboarding', true);

        emit(SignUpSuccess(myUser));
      } else {
        emit(SignUpFailure(response.data['detail'] ?? 'OTP verification failed'));
      }
    } catch (e) {
      emit(SignUpFailure(e.toString()));
    }
  }

  Future<String> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceData = 'Unknown Device';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceData = 'Android - ${androidInfo.model} (SDK ${androidInfo.version.sdkInt})';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceData = 'iOS - ${iosInfo.utsname.machine} (${iosInfo.systemVersion})';
    }
    return deviceData;
  }

  Future<String?> getFcmToken() async {
    final fcm = FirebaseMessaging.instance;
    return await fcm.getToken();
  }
}
