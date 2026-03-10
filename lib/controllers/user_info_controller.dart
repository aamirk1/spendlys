import 'package:get/get.dart';

class UserInfoController extends GetxController {
  final RxString profilePictureBase64 = ''.obs;

  void updateProfilePicture(String base64) {
    profilePictureBase64.value = base64;
  }
}
