import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
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
    );
    profilePictureBase64.value = myUser.value.image ?? '';
  }

  void updateProfilePicture(String base64) {
    profilePictureBase64.value = base64;
    _box.write('profilePicture', base64);
    // Use copyWith because fields are final
    myUser.value = myUser.value.copyWith(image: base64);
  }
}
