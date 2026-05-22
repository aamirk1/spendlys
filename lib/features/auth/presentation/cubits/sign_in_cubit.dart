import 'dart:io';
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

abstract class SignInState extends Equatable {
  const SignInState();
  @override
  List<Object?> get props => [];
}

class SignInInitial extends SignInState {}
class SignInLoading extends SignInState {}
class SignInSuccess extends SignInState {
  final MyUser user;
  const SignInSuccess(this.user);
  @override
  List<Object?> get props => [user];
}
class SignInFailure extends SignInState {
  final String errorMessage;
  const SignInFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class SignInCubit extends Cubit<SignInState> {
  final SecureStorageService _secureStorage;
  final GetStorage _box;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  SignInCubit(this._secureStorage, this._box)
      : super(SignInInitial());

  Future<void> signIn(String email, String password) async {
    emit(SignInLoading());
    try {
      final user = await signInWithEmailAndPassword(email, password);
      if (user != null) {
        emit(SignInSuccess(user));
      } else {
        emit(const SignInFailure("Authentication failed"));
      }
    } catch (e) {
      emit(SignInFailure(e.toString()));
    }
  }

  Future<MyUser?> signInWithEmailAndPassword(String email, String password) async {
    String deviceInfo = await _getDeviceDetails();
    String? fcmToken = await _firebaseMessaging.getToken();

    final apiClient = getIt<ApiClient>();
    final response = await apiClient.post(ApiConstants.login, data: {
      'email': email.trim(),
      'password': password.trim(),
      'device_info': deviceInfo,
      'fcm_token': fcmToken,
    });

    final data = response.data;
    final accessToken = data['access_token'];
    final customToken = data['firebase_custom_token'];
    final userData = data['user'];

    if (customToken != null) {
      await _auth
          .signInWithCustomToken(customToken)
          .timeout(const Duration(seconds: 30));
    }

    final user = await _finalizeLogin(userData, accessToken, deviceInfo, fcmToken);
    if (user != null) {
      await _secureStorage.saveCredentials(email.trim(), password.trim());
    }
    return user;
  }

  Future<MyUser?> syncUserByFirebaseToken(User firebaseUser) async {
    String deviceInfo = await _getDeviceDetails();
    String? fcmToken = await _firebaseMessaging.getToken();

    String safePhone = (firebaseUser.phoneNumber ?? "").replaceAll("+", "");
    if (safePhone.isEmpty) safePhone = firebaseUser.uid.substring(0, 10);

    final apiClient = getIt<ApiClient>();
    final response = await apiClient.post(ApiConstants.syncUser, data: {
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? "$safePhone@dailybachat.com",
      'password': "firebase_sync_placeholder",
      'phone_number': firebaseUser.phoneNumber,
      'name': firebaseUser.displayName ?? "User",
      'device_info': deviceInfo,
      'fcm_token': fcmToken,
    });

    if (response.data != null && response.data['user'] != null) {
      return await _finalizeLogin(
          response.data['user'], response.data['access_token'], deviceInfo, fcmToken);
    }
    return null;
  }

  Future<MyUser?> _finalizeLogin(
      dynamic userData, String? accessToken, String deviceInfo, String? fcmToken) async {
    if (userData == null) return null;

    if (accessToken != null) {
      await _secureStorage.saveToken(accessToken);
    }

    MyUser myUser = MyUser(
      userId: userData['id'] ?? '',
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phone_number'] ?? '',
      lastLogin: Timestamp.now(),
      isPremium: userData['is_premium'] ?? false,
    );

    _box.write("isLoggedIn", true);
    _box.write("userId", myUser.userId);
    _box.write("name", myUser.name);
    _box.write("email", myUser.email);
    _box.write("phoneNumber", myUser.phoneNumber);
    _box.write("isPremium", myUser.isPremium);
    _box.write("deviceInfo", deviceInfo);
    _box.write("fcmToken", fcmToken);
    _box.write("hasSeenOnboarding", true);

    return myUser;
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

  Future<void> logout() async {
    await _auth.signOut();
    await _secureStorage.clearAll();
    _box.erase();
    emit(SignInInitial());
  }
}
