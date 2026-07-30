import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/app/data/models/myuser.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoController extends GetxController {
  final _box = GetStorage();
  final Rx<MyUser> myUser = MyUser(
    userId: '',
    name: '',
    email: '',
    phoneNumber: '',
    lastLogin: Timestamp.now(),
  ).obs;

  final RxString profilePictureBase64 = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshUser();
    fetchLatestProfile();
  }

  void refreshUser() {
    myUser.value = MyUser(
      userId: _box.read('userId') ?? '',
      name: _box.read('name') ?? '',
      email: _box.read('email') ?? '',
      phoneNumber: _box.read('phoneNumber') ?? '',
      lastLogin: Timestamp.now(), // Fallback
      isPremium: _box.read('isPremium') ?? false,
      image: _box.read('profilePicture') ?? '',
      referralCode: _box.read('referralCode'),
      referredById: _box.read('referredById'),
      referralCount: _box.read('referralCount') ?? 0,
    );
    profilePictureBase64.value = myUser.value.image ?? '';
  }

  Future<void> fetchLatestProfile() async {
    try {
      final userId = _box.read('userId');
      if (userId == null || userId.isEmpty) return;

      final response = await ApiService.get(
        '/auth/me',
        headers: {'x-user-id': userId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _box.write("isPremium", data['is_premium'] ?? false);
        if (data['premium_expiry'] != null) {
          _box.write("premiumExpiry", data['premium_expiry']);
        }
        _box.write("referralCode", data['referral_code']);
        _box.write("referredById", data['referred_by_id']);
        _box.write("referralCount", data['referral_count'] ?? 0);

        refreshUser();
      }
    } catch (e) {
      debugPrint("Error fetching latest profile: $e");
    }
  }

  void updateProfilePicture(String base64) {
    profilePictureBase64.value = base64;
    _box.write('profilePicture', base64);
    // Use copyWith because fields are final
    myUser.value = myUser.value.copyWith(image: base64);
  }
}
